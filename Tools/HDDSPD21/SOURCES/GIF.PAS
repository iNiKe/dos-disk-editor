(************************************************************************)
(*  Title               : GIF.PAS                                       *)
(*                                                                      *)
(*  Original Title      : WGIFASM.PAS                                   *)
(*                                                                      *)
(*  By                  : Martin Israelsen                              *)
(*                                                                      *)
(*  Description         : An asm-rewritten version of WriteGif.Pas      *)
(*                        Original from "Tips & Tricks in Turbo Pascal" *)
(*                        Systime 1993. ISBN 87 7783 192 6              *)
(*                                                                      *)
(*                        Only short-tested for bugzzz                  *)
(*                                                                      *)
(*                        WGIFASM can only be used in EGA/VGA 16-color  *)
(*                        modes, with 640 pixels screenwidth. If you    *)
(*                        want to use it in other modes, the FGetPixel  *)
(*                        have to be rewritten.                         *)
(*                                                                      *)
(************************************************************************)
(*                                                                      *)
(*        Modified by Michael Radchenko, 2:5025/25@fidonet              *)
(*                                                                      *)
(*                       þ Removed GRAPH.TPU-specific code.             *)
(*                         Now it works without BGI drivers but only in *)
(*                         640x480 16 colors mode (12h)                 *)
(*                                                                      *)
(*                       þ Defines.inc & typ.pas files now included     *)
(*                                                                      *)
(************************************************************************)
(*$I-*)  (* Iocheck off         *)
(*$F+*)  (* Force FAR call      *)
(*$V-*)  (* Relaxed VAR check   *)
(*$R-*)  (* Range check off     *)
(*$S-*)  (* Stack check off     *)
(*$Q-*)  (* Overflow off        *)
(*$D-*)  (* Debug off           *)
(*$L-*)  (* Linenumber off      *)

(*Define Trace*) (* Turn on this directive to enable "trace"  *)

Unit GIF;

Interface

uses VGA;

Const
   CEgaCtrl  = $03CE;
   CVideoSeg = $A000;
Type
   PByte     = ^Byte;
   PWord     = ^Word;
   PLong     = ^Longint;

   PByteArr  = ^TByteArr;
   TByteArr  = Array[1..64000] Of Byte;

   PfStr     = String[100];

   TGPaletteRec = Record
                     Red,
                     Green,
                     Blue   : Byte;
                  End;

   PGPalette    = ^TGPalette;
   TGPalette    = Array[0..255] Of TGPaletteRec;

   TGifDescrip  = Record
                     ScreenWidth,          (* Width and height for whole picture *)
                     ScreenHeight : Word;
                     GifInfo,

                     (* GIFInfo contains the following information:              *)
                     (* Bit 0000 0000                                            *)
                     (*     1xxx xxxx - True if theres a global palette          *)
                     (*     x111 xxxx - Bits/color                               *)
                     (*     xxxx 1xxx - Reserved                                 *)
                     (*     xxxx x111 - Bits per. Pixel (no. color) in the image *)

                     BackGround,           (* Evt. background color              *)
                     EofMark      : Byte;  (* Terminator for this  record        *)
                  End;

   TGifImageRec = Record
                     LeftOffset,           (* Image position related to the      *)
                     TopOffset,            (* whole image.                       *)
                     ImageWidth,           (* Width and height for this image    *)
                     ImageHeight  : Word;
                     ImageInfo    : Byte;

                     (* ImageInfo contains the following information:            *)
                     (* Bit 0000 0000                                            *)
                     (*     1xxx xxxx - True if local palette is to be used      *)
                     (*     x1xx xxxx - True if the image is interlaced          *)
                     (*     xx11 1xxx - Not Used                                 *)
                     (*     xxxx x111 - Bits per pixel (no. color) in the image  *)
                  End;

Function  MakeGif(FNavn: PfStr; Width,Height,BackColor,Bpp: Word; PColor: PGPalette): Boolean;
Function  WriteImage(Left,Top,Width,Height,Bpp: Word; Interlace: Boolean; PColor: PGPalette): Boolean;
Procedure FinishGif;
Procedure WriteScreenToGif(Colors: Integer; FName: String);
Procedure WriteGIF(FName: String);

Implementation

Const
  CGifImageSeperator = ',';
  CGifTerminator     = ';';

  CTableSize         = 5003;
  CMaxCode           = 4095;

  GetMaxX            = 639;
  GetMaxY            = 479;

Type
  TCodeEntry  = Record
                   PriorCode : Integer;
                   CodeId    : Integer;
                   AddedChar : Byte;
                End;

  PWriteGif  = ^TWriteGif;
  TWriteGif  = Record
                   CodeSize,
                   ClearCode,
                   EofCode,
                   MinCode,
                   MaxCode,
                   BitsLeft,
                   FreeCode,
                   SuffixChar,
                   Md,Gifx,
                   Gify         : Integer;
                   CodeBuffer   : Array[0..259] Of Byte;
                   CodeTabel    : Array[0..CTableSize] Of TCodeEntry;

                   BitOffset,
                   ByteOffset,
                   InterlacePass : Word;
                   MinCodeSize   : Byte;
                   ImageDes      : TGifImageRec;
                   GifFil        : File;

                   PlaneNo       : Integer;
                   PixelArr      : Array[0..639] Of Byte;
                End;

Var
  PWGif  : PWriteGif;

Procedure InitLzwTree; Assembler;
Asm
   Les    Di,PWGif                       (* Es:Di -> PWGif *)
   Mov    Ah,0
   Mov    Al,Byte Ptr Es:[Di.TWriteGif.MinCodeSize]
   Mov    Dx,Ax
   Inc    Dx                             (* CodeSize in Dx *)
   Mov    Es:[Di.TWriteGif.CodeSize],Dx
   Mov    Cx,Ax
   Mov    Bx,1
   Shl    Bx,Cl
   Mov    Es:[Di.TWriteGif.ClearCode],Bx (* ClearCode:=1 Shl MinCodeSize *)
   Inc    Bx
   Mov    Es:[Di.TWriteGif.EofCode],Bx   (* EofCode:=Succ(ClearCode)     *)
   Inc    Bx
   Mov    Es:[Di.TWriteGif.FreeCode],Bx  (* FreeCode:=Succ(EofCode)      *)
   Mov    Cx,Dx
   Mov    Ax,1
   Shl    Ax,Cl
   Mov    Es:[Di.TWriteGif.MaxCode],Ax   (* MaxCode:=1 Shl CodeSize      *)

   Mov    Cx,CTableSize
   Lea    Di,Es:[Di.TWriteGif.CodeTabel] (* For I:=0 To CTableSize Do *)
   Xor    Ax,Ax
   Add    Di,2                           (* Offset for CodeId *)
@@FillLoop:
   Mov    Es:[Di],Ax                     (* CodeTable[i].CodeId:=0;         *)
   Add    Di,Type TCodeEntry
   Loop   @@FillLoop
End;

Function FGetPixel(X,Y: Integer): Byte; Assembler;
(************************************************************)
(*                                                          *)
(* FReadPixel. Works by combining the 4 planes, after they  *)
(* have been read from the screen                           *)
(*                                                          *)
(************************************************************)
Const
  PlaneByteSize = 80;
  EgaCtrl       = $03ce;
Var
  PlaneBuffer: Array[0..3] Of Array[1..PlaneByteSize] Of Byte;
Asm
   Cld

   (* Check to se if the currect Y-value is in the buffer  *)

   Les    Di,PWGif
   Mov    Ax,Y
   Cmp    Ax,Es:[Di.TWriteGif.PlaneNo]
   Je     @@BufferLoaded
   Mov    Es:[Di.TWriteGif.PlaneNo],Ax

   (* It wasnt. Now read the planes from the videobuffer *)

   Push   Ds
   Mov    Bx,PlaneByteSize
   Mul    Bx
   Mov    Si,Ax
   (*$IfDef DPMI*)       (* 6.0 compability        *)
   Mov    Ax,SegA000
   (*$Else*)
   Mov    Ax,$A000
   (*$Endif*)
   Mov    Ds,Ax          (* DS:SI -> Videobuffer *)

   Push   Ss
   Pop    Es
   Lea    Di,SS:PlaneBuffer  (* ES:DI -> PlaneBuffer *)

   Mov    Bx,4
   Mov    Dx,$03ce           (* EgaController        *)

@@LoadPlanes:

   Push   Si
   Mov    Al,$04
   Mov    Ah,Bl
   Dec    Ah
   Out    Dx,Ax

   Mov    Cx,PlaneByteSize / 2
   Rep    MovSw
   Pop    Si

   Dec    Bx
   Jnz    @@LoadPlanes

   Pop    Ds

   (* Allright, the 4 planes have to be combined to ordinary  *)
   (* pixelvalues. The best 80x86 way to do it, is to get 4*1 *)
   (* plane bytes, and combine 8 pixels in every loop         *)

   Push   Ds

   Les    Di,PWGif
   Lea    Di,Es:[Di.TWriteGif.PixelArr]

   Push   Ss
   Pop    Ds

   Lea    Si,SS:PlaneBuffer

   (* First fill PixelArr *)
   Mov    Cx,PlaneByteSize
@@LineLoop:
   Mov    Bl,Ds:[Si]
   Mov    Bh,Ds:[Si+PlaneByteSize]
   Mov    Dl,Ds:[Si+(PlaneByteSize*2)]
   Mov    Dh,Ds:[Si+(PlaneByteSize*3)]
   Inc    Si

   Push   Cx
   Mov    Cx,8
@@BitLoop:
   Mov    Al,0
   Shl    Bl,1
   Rcl    Al,1
   Shl    Bh,1
   Rcl    Al,1
   Shl    Dl,1
   Rcl    Al,1
   Shl    Dh,1
   Rcl    Al,1
   Stosb
   Loop   @@BitLoop

   Pop    Cx
   Loop   @@LineLoop

   Pop    Ds
   Les    Di,PWGif

@@BufferLoaded:

   (* Here the pixelvalue is returned *)

   Lea    Di,Es:[Di.TWriteGif.PixelArr]
   Add    Di,X
   Mov    Ah,0
   Mov    Al,Byte Ptr Es:[Di]
End;

Function GetGifData: Integer; Assembler;
Asm
   (* First get a pixel fra FGetPixel/GetPixel     *)
   (* Registers used: DX: Result, CX: Gify         *)

   Les    Di,PWGif
   Mov    Ax,Es:[Di.TWriteGif.Gifx]
   Add    Ax,Es:[Di.TWriteGif.ImageDes.TGifImageRec.LeftOffset]
   Push   Ax
   Mov    Ax,Es:[Di.TWriteGif.Gify]
   Add    Ax,Es:[Di.TWriteGif.ImageDes.TGifImageRec.TopOffset]
   Push   Ax
   Call   FGetPixel
   Mov    Dx,Ax

   (*$IfDef Trace*)
   Push   Dx
   Les    Di,PWGif
   Cmp    Es:[Di.TWriteGif.Gifx],0
   Jnz    @@NoTrace

   Mov    Ax,Es:[Di.TWriteGif.Gifx]
   Add    Ax,Es:[Di.TWriteGif.ImageDes.TGifImageRec.LeftOffset]
   Push   Ax
   Mov    Ax,Es:[Di.TWriteGif.Gify]
   Add    Ax,Es:[Di.TWriteGif.ImageDes.TGifImageRec.TopOffset]
   Push   Ax
   Mov    Ax,15
   Push   Ax
   Call   PutPixel
@@NoTrace:
   Pop   Dx
   (*$Endif*)

   Les   Di,PWGif
   Inc   Es:[Di.TWriteGif.Gifx]
   Mov   Ax,Es:[Di.TWriteGif.Gifx]
   Cmp   Ax,Es:[Di.TWriteGif.ImageDes.TGifImageRec.ImageWidth]
   Jne   @@L2

   Mov   Es:[Di.TWriteGif.Gifx],0
   Mov   Cx,Es:[Di.TWriteGif.Gify]  (* Gify In CX *)
   Cmp   Es:[Di.TWriteGif.Interlacepass],0
   Jnz   @@IPStart
   Cmp   Cx,Es:[Di.TWriteGif.ImageDes.TGifImageRec.ImageHeight]
   Jl    @@L0
   Mov   Dx,-1
@@L0:
   Inc   Cx
   Jmp   @@L1

   (* Instead of a case, the Interlace values is placed   *)
   (* in a CS-table.                                      *)

@@IP1:
   Dw    0,8,8,4,2
@@IP2:
   Dw    0,4,2,1,-1

@@IPStart:
   Mov   Bx,Es:[Di.TWriteGif.InterlacePass]
   Shl   Bx,1
   Mov   Cx,Es:[Di.TWriteGif.Gify]
   Lea   Si,Cs:@@IP1
   Mov   Ax,Cs:[Si+Bx]        (* "CASE" *)
   Add   Cx,Ax

   Cmp   Cx,Es:[Di.TWriteGif.ImageDes.TGifImageRec.ImageHeight]
   Jb    @@L1

   Inc   Es:[Di.TWriteGif.InterlacePass]

   Lea   Si,Cs:@@IP2
   Mov   Cx,Cs:[Si+Bx]        (* "CASE" *)
   Cmp   Cx,-1
   Jne   @@L1
   Mov   Dx,-1
@@L1:
   Mov   Es:[Di.TWriteGif.GifY],Cx
@@L2:
   Mov   Es:[Di.TWriteGif.SuffixChar],Dx
   Mov   Ax,Dx
End;

Procedure PutByte(B: Byte);
Var
  X: Word;
Begin
   BlockWrite(PWGif^.GifFil,B,1,X);
End;

Procedure PutBlock(Var Buffer; Count: Integer);
Var
  X: Word;
Begin
   BlockWrite(PWGIF^.GifFil,Buffer,Count,X);
End;

Procedure PutString(S: String);
Begin
   PutBlock(S[1],Length(S));
End;

Procedure WriteCode(Code: Integer); Assembler;
Asm
   Les   Di,PWGif
   Mov   Ax,Es:[Di.TWriteGif.BitOffset]
   Mov   Bx,Ax
   Mov   Cl,3
   Shr   Ax,Cl          (* ByteOffset:=BitOffset Shr 3 *)
   Mov   Es:[Di.TWriteGif.ByteOffset],Ax
   And   Bx,7           (* Bitsleft:=BitOffset And 7 *)
   Mov   Es:[Di.TWriteGif.BitsLeft],Bx

   Cmp   Ax,254
   Jl    @@NoBlock      (* If ByteOffset <254 Then Jmp NoBlock *)

   Push  Ax
   Push  Ax             (* Push ByteOffset *)

   Call  PutByte        (* Call Putbyte    *)

   Pop   Ax             (* Pop Byte Offset *)

   Les   Di,PWGif
   Lea   Di,Es:[Di.TWriteGif.CodeBuffer]
   Push  Es             (* Push @CodeBuffer *)
   Push  Di
   Push  Ax             (* Push ByteOffset  *)
   Call  PutBlock

   Les   Di,PWGif       (* Es:Di -> PWGif   *)

   Mov   Ax,Es:[Di.TWriteGif.BitsLeft]
   Mov   Es:[Di.TWriteGif.BitOffset],Ax              (* BitOffset:=BitsLeft                   *)

   Xor   Bx,Bx
   XChg  Bx,Es:[Di.TWriteGif.ByteOffset]             (* ByteOffset:=0                         *)
   Mov   Al,Byte Ptr Es:[Di.TWriteGif.CodeBuffer+Bx]
   Mov   Byte Ptr Es:[Di.TWriteGif.CodeBuffer],Al    (* CodeBuffer[0]:=CodeBuffer[ByteOffset] *)
@@NoBlock:

   Mov   Ax,Code                                     (* Code i Ax                             *)
   Mov   Bx,Es:[Di.TWriteGif.ByteOffset]             (* ByteOffset i Bx                       *)
   Mov   Cx,Es:[Di.TWriteGif.BitsLeft]

   Or    Cx,Cx          (* Is Bitsleft = 0 ?                *)
   Jz    @@StoreWord

   Cwd                  (* Longint(Code)                    *)

@@ShlLoop:              (* LCode (Dx:Ax):=Code Shl Bitsleft *)
   Shl   Ax,1
   Rcl   Dx,1
   Loop  @@ShlLoop

   Or    Byte Ptr Es:[Di.TWriteGif.CodeBuffer+Bx],Al (* CodeBuffer[ByteOffset]:=CodeBuffer[ByteOffset] Or Code And $FF*)
   Inc   Bx             (* Inc(CodeBuffer)                  *)

   Mov   Al,Ah
   Mov   Ah,Dl

@@StoreWord:
   Mov   Word Ptr Es:[Di.TWriteGif.CodeBuffer+Bx],Ax
   Mov   Ax,Es:[Di.TWriteGif.CodeSize]
   Add   Es:[Di.TWriteGif.BitOffset],Ax
End;

Function MakeGif(FNavn: PfStr; Width,Height,BackColor,Bpp: Word; PColor: PGPalette): Boolean;
Label
  Exit;
Var
  GifDes : TGifDescrip;
Begin
   (* This code is only done once, so there is no need to optimize it *)

   MakeGif:=False;

   New(PWGif);

   With PWGif^ Do
   Begin
      Assign(GifFil,FNavn); ReWrite(GifFil,1);
      If IoResult<>0 Then
      Begin
         Dispose(PWGif);
         Goto Exit;
      End;

      PutString('GIF87a');

      With GifDes Do
      Begin
         ScreenWidth:=Width;
         ScreenHeight:=Height;

         GifInfo:=Pred(Bpp);
         If PColor<>Nil Then GifInfo:=GifInfo Or $80;

         BackGround:=0;
         EofMark:=0;
      End;

      PutBlock(GifDes,Sizeof(GifDes));

      If PColor<>Nil Then PutBlock(PColor^,(1 Shl Bpp)*3);
   End;

   MakeGif:=True;

   Exit:
End;

Function WriteImage(Left,Top,Width,Height,Bpp: Word; Interlace: Boolean; PColor: PGPalette): Boolean;
Label
  Exit,Break;
Var
  I        : Integer;
Begin
   WriteImage:=False;

   With PWGif^ Do
   Begin
      PutByte(Ord(CGifImageSeperator));

      With ImageDes Do
      Begin
         LeftOffset:=Left;
         TopOffset:=Top;
         ImageWidth:=Width-Left;
         ImageHeight:=Height-Top;

         (* calculate mincode size *)

         MinCodeSize:=Bpp;
         ImageInfo:=Pred(MinCodeSize);
         If Interlace Then ImageInfo:=ImageInfo Or $40;
         If PColor<>Nil Then ImageInfo:=ImageInfo Or $80;

         InterlacePass:=Ord(Interlace);

         PutBlock(ImageDes,Sizeof(ImageDes));

         If PColor<>Nil Then PutBlock(PColor^,(1 Shl Bpp)*3);
      End;

      PutByte(MinCodeSize);

      BitOffset:=0;
      InitLzwTree;
      WriteCode(ClearCode);

      GifX:=0; GifY:=0;

      SuffixChar:=GetGifData;

      If SuffixChar>=0 Then
      Begin
         Asm
            (* The compressiorrutine is primary a quick translation from *)
            (* pascal to assembler, and can be better optimized, for     *)
            (* example by using more register values. Anyway the code is *)
            (* still much quicker than Turbo Pascal.                     *)

            (* Registervars    : PrefixCode: Dx                          *)
            (*                   Hx        : Si                          *)

            Les   Di,PWGif
            Mov   Dx,Es:[Di.TWriteGif.SuffixChar]

         @@GifLoop:

            Push  Dx     (* Save/Restore PrefixCode *)
            Call  GetGifData
            Pop   Dx
            Les   Di,PWGif
            Cmp   Ax,0
            Jge   @@L0
            Jmp   @@GifExit

         @@L0:
            Push  Dx    (* Save/Restore PrefixCode *)
            Mov   Ax,Es:[TWriteGif.SuffixChar]
            Mov   Cl,5
            Shl   Ax,Cl
            Xor   Ax,Dx (* Xor Ax,PrefixCode *)
            Cwd
            Mov   Cx,CTableSize
            IDiv  Cx
            Mov   Si,Dx
            Mov   Es:[Di.TWriteGif.Md],1
            Pop   Dx

         @@TableLoop:

            Push  Dx  (* Save/Restore PrefixCode *)
            Mov   Ax,Type TCodeEntry
            Mul   Si
            Mov   Bx,Ax                (* CodeTable Index In BX *)
            Pop   Dx

            Cmp   Es:[Di.TWriteGif.CodeTabel.TCodeEntry.CodeId+Bx],0
            Jnz   @@L4

            Push  Dx  (* Save/Restore PrefixCode,Hx,Index *)
            Push  Si
            Push  Bx
            Push  Dx
            Call  WriteCode
            Pop   Bx
            Pop   Si
            Pop   Dx
            Les   Di,PWGif

            Mov   Ax,Es:[Di.TWriteGif.FreeCode]
            Mov   Es:[Di.TWriteGif.Md],Ax

            Cmp   Es:[Di.TWriteGif.FreeCode],CTableSize
            Ja    @@L1

            Mov   Es:[Di.TWriteGif.CodeTabel.TCodeEntry.PriorCode+Bx],Dx
            Mov   Ax,Es:[Di.TWriteGif.SuffixChar]
            Mov   Es:[Di.TWriteGif.CodeTabel.TCodeEntry.AddedChar+Bx],Al
            Mov   Ax,Es:[Di.TWriteGif.FreeCode]
            Mov   Es:[Di.TWriteGif.CodeTabel.TCodeEntry.CodeId+Bx],Ax
            Inc   Es:[Di.TWriteGif.FreeCode]

          @@L1:

            Mov   Ax,Es:[Di.TWriteGif.Md]
            Cmp   Ax,Es:[Di.TWriteGif.MaxCode]
            Jnz   @@L3

            Cmp   Es:[Di.TWriteGif.CodeSize],12
            Jae   @@L2

            Inc   Es:[Di.TWriteGif.CodeSize]
            Shl   Es:[Di.TWriteGif.MaxCode],1
            Jmp   @@L3

         @@L2:
            Push  Dx  (* Save/Restore PrefixCode,Hx,Index *)
            Push  Si
            Push  Bx
            Push  Es:[Di.TWriteGif.ClearCode]
            Call  WriteCode
            Call  InitLZWTree
            Les   Di,PWGIF
            Pop   Bx
            Pop   Si
            Pop   Dx

         @@L3:
            Mov   Dx,Es:[Di.TWriteGif.SuffixChar]
            Jmp   @@L7

         @@L4:
            Cmp   Dx,Es:[Di.TWriteGif.CodeTabel.TCodeEntry.PriorCode+Bx]
            Jnz   @@L5
            Mov   Al,Es:[Di.TWriteGif.CodeTabel.TCodeEntry.AddedChar+Bx]
            Cmp   Al,Byte Ptr Es:[Di.TWriteGif.SuffixChar]
            Jnz   @@L5
            Mov   Dx,Es:[Di.TWriteGif.CodeTabel.TCodeEntry.CodeId+Bx]
            Jmp   @@L7
         @@L5:
            Add   Si,Es:[Di.TWriteGif.Md]
            Add   Es:[Di.TWriteGif.Md],2

            Cmp   Si,CTableSize
            Jl    @@L6
            Sub   Si,CTableSize
         @@L6:
            Jmp   @@TableLoop
         @@L7:
            Jmp   @@GifLoop
         @@GifExit:
            Cmp   Es:[Di.TWriteGif.SuffixChar],-1
            Jnz   Exit

            Push  Dx
            Call  WriteCode
         End;
      End Else
      Begin
         If SuffixChar<>-1 Then Goto Exit;
      End;

      WriteCode(EofCode);

      If BitOffset>0 Then
      Begin
         I:=(BitOffset+7) Div 8;
         PutByte(I);
         PutBlock(CodeBuffer[0],I);
      End;

      PutByte(0);

      WriteImage:=True;
   End;

   Exit:
End;

Procedure FinishGif;
Begin
   With PWGif^ Do
   Begin
      PutByte(Ord(CGIFTerminator));
      Close(GifFil);
   End;
End;

Procedure WriteScreenToGif(Colors: Integer; FName: String);
Const
   NormPal = #$00#$00#$00#$00#$00#$AA#$00#$AA#$00+
             #$00#$AA#$AA#$AA#$00#$00#$AA#$00#$AA+
             #$AA#$55#$00#$AA#$AA#$AA#$55#$55#$55+
             #$55#$55#$FF#$55#$FF#$55#$55#$FF#$FF+
             #$FF#$55#$55#$FF#$55#$FF#$FF#$FF#$55+
             #$FF#$FF#$FF;
Var
  Palette : TGPalette;
  S       : String;
  Bpp     : Word;
Begin
   If Colors=16 Then
   Begin
      S:=NormPal; Move(S[1],Palette,Length(S)); Bpp:=4;
   End Else
   Begin
      Writeln('To use WGIFASM with 256-color pictures');
      Writeln('the palette should be set in this code');

      (* Palette:= 256-Palette *) Bpp:=8;
   End;

   If MakeGif(FName,Succ(GetMaxx),Succ(GetMaxy),0,Bpp,@Palette) Then
   Begin
      If WriteImage(0,0,Succ(GetMaxx),Succ(GetMaxy),Bpp,False,Nil) Then;
      FinishGif;
   End Else
   Begin
      Writeln('Error during MakeGif'^g);
   End;
End;

Procedure WriteGIF(FName: String);
begin
  WriteScreenToGif(16, FName);
end;

End.


