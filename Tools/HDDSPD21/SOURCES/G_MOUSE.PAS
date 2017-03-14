{ --------------------------------------------------------------------------- }
{ G_MOUSE.PAS  g_Mouse Interface Unit - graphical mouse pointer in text mode  }
{             80x25. Borland Pascal 7 version. Supports both real and protec- }
{             ted modes.                                                      }
{                                                                             }
{                                                              Version 1.53.7 }
{                                                         Written by Bobby Z. }
{                                          Copyright(c) 1993-96 by B-coolWare }
{ --------------------------------------------------------------------------- }
{
                                            "Nice, nice. Not ruling, nice..."

                                                            (Mel Brooks)

  License.
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

 SOFTWARE STATUS:

 This software is a copyrighted free one. This means that it is distributed
  free of charge and that you must keep the copyright notice with it. Usually
  this also means that you cannot modify the code, but it is not the case with
  this one (see grant of license for details). Note that it is not public
  domain software, that is author reserves copyright for it as well as some
  other rights.

 GRANT OF LICENSE:

 You are hereby granted the right to use this software in any non-commercial
  products provided that you keep the copyright notice unchanged. Using this
  software in commercial products (including shareware) requires prior written
  consent from the author.
 You are also granted the right to distribute this code freely in its original
  unmodified form provided that you do not charge any fee that exceeds your
  expences arising from distributing it (for example, uploading to commercial
  network) but not exceeding $5 in total.
 You also may modify the code to add new features or eliminate bugs or
  incompatibilites you discovered and distribute modified code provided that
  you add a notice that the code was modified. If you do any modifications
  to the code, please send me the modified version so that I'll be able to
  reflect changes in the next releases. Regardless of the extent of modifica-
  tions the code should remain free and will still copyright(c) by B-coolWare.
 If you disobey any of the terms mentioned you'll be liable for violation of
  Russian Copyright Law in Computer Programs and Databases as well as other
  national or international laws and treaties. The parties that acquired this
  code from you will still have their rights as long as they comply with this
  license.

 DISCLAIMER:

 Author disclaims all warranties, whether express or implied, of code quality,
  reliability or fitness for a particular purpose. I can only guarantee that it
  will occupy disk space. Though this code was thoroughly tested, the possibi-
  lity of errors can't be eliminated. Do not blame me if something goes wrong -
  you were warned.

 AUTHOR'S LIABILITY:

 In case of taking damage due to use, misuse or inability to use, this code,
  whether it is physical damage to your hardware, loss of data or profits,
  or any similar damages author shall not be liable for it. The whole risk is
  with you.

 AUTHOR'S EXCLUSIVE RIGHTS:

 Author reserves the right to use this code in any commercial or non-
  commercial software of his own design, the right to change the code partially
  or in whole without notification to its users and the right to change its
  status as he sees fit (to shareware, for example) in future releases.

 How to contact the author:
 ~~~~~~~~~~~~~~~~~~~~~~~~~~
 If you experiencing problems with this code or have any suggestions, bug
  fixes or just wanna chat, refer to the following addresses:

  e-mail (preferrable):

  2:5028/52.6 (FIDOnet)
  loki@cnit.uniyar.ac.ru (internet)

  snail mail:

  150031,
  10/4/13 Dobrynina Str.,
  Yaroslavl,
  Russia

  Vladimir M. Zakharychev (aka Bobby Z.)

  Letters both in Russian and in English are welcome. Please do not use any
  other language if you want to be answered. Letter bombs are always
  returned to sender... shhhh-boom-BANG! :)

  Thank you for your interest in B-coolWare products.

 ------------------------------------------------------------------------------

 Description.
 ~~~~~~~~~~~~
 This Borland Pascal unit was developed to give you the opportunity to improve
 user interface of your DOS text mode applications written in Pascal by adding
 "graphical" screen controls to your applications. The only implemented control
 is "graphical" mouse pointer, but routines provided in this unit can also be
 used to reprogram the appearance of any characters. The unit supports both
 real and protected modes and can be used with almost all TUI packages
 available for Pascal programmers, which include Turbo Professional and Object
 Professional by TurboPower Software, Turbo Vision 1.0 and 2.0 by Borland Intl.
 (with some limitations described below) as well as other commercial or
 handmade tools.

 Actually this unit is a port from assembly language version 1.42 of g_Mouse
 with simplified initialization. Version 1.42 did not support protected mode
 because Borland's extender does not handle mouse function 14h (exchange
 handlers) properly (this function was used to chain any existing handlers
 to g_Mouse's one). Version 1.53.7 is compatible with RTM and uses only calls
 proved to work correctly under it. And it is much easier to use.


 Programmer's notes:
 ~~~~~~~~~~~~~~~~~~~

  1. This code intercepts mouse services interrupt (33h) thus making
     its use extremely easy: you just need to insert reference to g_Mouse in
     "uses" clause of your application and use mouse as you always do - g_Mouse
     will handle all other stuff by itself. Deinitialization of system is
     performed automatically thru Pascal's ExitProc mechanism. All standard
     mouse functions still work o.k. with this code with some exceptions in
     protected mode which are due to RTM's limited support for those functions.

  2. If you wish to use this code within your Turbo Vision applications,
     you'll have to change View.WriteView's logic in part determining if mouse
     pointer is within area to be redrawn. As now mouse pointer occupies
     4 characters instead of 1 it may happen that WriteView determine that
     mouse pointer is outside the area and do not hide it while it actually
     should.
     Also note that you should call DoneGMouse explicitly AFTER any call to
     DoneEvents and resume g_Mouse operation by calling InitGMouse BEFORE
     call to InitEvents. On program startup/exit it is done automatically but
     when you do something weird like executing another process you should
     shut down TV's managers first and then shut down g_Mouse. This makes
     TV 2.0's TApplication.DOSShell unusable. You should always override it if
     you intend to exec child processes from within your TV application using
     TApplication.DOSShell method (see example program TUTOR01.PAS).

  3. One conditional define affects the way code is compiled:

     TrackVideoMode

     If this is defined then mouse interrupt handler instantly calls INT 10h
     function 0Fh (get current video mode) and suspends if current video mode
     is other than 03h (80x25 color). Operation becomes a bit slower but you
     won't get any probs when switching to other modes (80x50 for example).
     You'll have to add other modes you want to support by yourself (like
     SuperVGA 130xXX modes with 8x14 and 8x16 characters).

  4. If you intend to use two different fonts simultaneously, you should make a
     call to setFontMode routine right after you download fonts to video RAM
     and set appropriate mode of operation for g_Mouse. See example program
     GMTEST.PAS for typical implementation.

  5. This code written with speed in mind and uses advanced instructions of
     Intel's 80286 and newer processors. Thus it cannot be used in programs
     that should be able to run on Intel 8088 and 8086 processors. I didn't
     bother with (*$IFOPT G+*) for these CPUs are quite rare now.


 History:
 ~~~~~~~~

   26 Oct 1994   - ported and adapted assembly language version 1.42 to Pascal.
                 - adapted for protected mode operation.
   08 Dec 1994   - version 1.51.7 introduced:
                 - fixed TrackVideoMode operation - it didn't work as expected.
                 - added ability to program any font, not only #0. To learn
                   how to exploit this new feature refer to SelectFontBank
                   routine description below.
                 - eventually this code didn't require any bug-fixes! This is
                   kinda strange... I hope it won't crash anything someday. :)
   10 Jan 1995   - fixed some spelling errors in docs.
   06 Apr 1995   - version 1.52.7 introduced:
                 - added support for two fonts displayed simultaneously. Now
                   mouse pointer is diplayed properly in this mode.
                 - fixed font bank addressing bug - on VGA banks are 8K in size
                   but mapped in VRAM as #0 #4 #1 #5 #2 #6 #3 #7 to maintain
                   compatibility with EGA bank addressing.
   06 Jun 1995   - some minor fixes made, nothing serious to change version.
                 - added file README.1ST to the distribution archive.
                 - added Set30Lines routine.
   29 Nov 1996   - version 1.53.7:
                 - added text file describing how to patch Turbo Vision to
                   support g_Mouse.
                 - some misc improvements made.

}

{$E-,G+,N-,O-,S-,P-,R-,X+}
{$C PRELOAD FIXED PERMANENT}

{$DEFINE TrackVideoMode}

unit g_Mouse;

interface

type
        CharBitmap = array[0..31] of Byte; { character Bitmap array }

procedure initGMouse( FlipMode : Boolean );
{ initialize g_Mouse system. FlipMode affects the movement of pointer. If
  it is True, the pointer will move smoothly, but characters will appear to
  be somehow "wider" then usually. }

procedure doneGMouse;
{ deinitialize g_Mouse system. Called automatically on program end, but you
  will need to do it manually when executing child processes or something like
  that. }

procedure setMouseChars(C1Code, C2Code, C3Code, C4Code : Byte);
{ change characters used for mouse pointer. Note that these characters' maps
  will be corrupted at runtime reflecting mouse movement. You should hide
  mouse pointer before invoking this procedure. }

procedure setPointerShape( var AND_Mask, OR_Mask );
{ used to change mouse pointer shape. AND_Mask and OR_Mask should be arrays of
  at least CharSize bytes. }

procedure getPointerShape( var AND_Mask, OR_Mask );
{ fills AND_Mask and OR_Mask arrays with current -and- and -or- masks that
  represent mouse pointer. }

procedure getCharBitmap( C : Word; var Bitmap );
{ returns bitmap for character C. If requested character is one of those used
  to represent mouse pointer the Bitmap will be filled with zeros. }

procedure setCharBitmap( C : Word; var Bitmap );
{ sets character C's bitmap to Bitmap. Unused scanlines should be zeroed.
  Does not change characters currently used to represent mouse pointer. }

procedure selectFontBank( FontBank : Byte );
{ selects font bank to use when reading/writing character bitmaps }

procedure setFontMode( TwoFonts : Boolean; fontBank1, fontBank2 : Byte );
{ sets internal variables according to TwoFonts parameter to reflect if two }
{ different font banks displayed simultaneously }

procedure setDisplayableFonts( Font1, Font2 : Byte );
{ enables Font1 and Font2 to be displayed simultaneously. Bit 3 (08h) of
  character attribute selects which font to use when displaying certain
  character. }

procedure set30Lines;
{ sets 80x30 display mode on VGA. Characters are still 16 pixels high, but
  there's 30 lines on screen. Be sure to call InitGMouse AFTER this function
  or else the screen will be wrapped horizontally when using 8 bits per
  character mode. }

const
        Active   : Boolean = False;     { gMouse system is active }
        CharSize : Word = 16;           { character height in scanlines }

implementation

uses Dos;

type
        VideoType = (vtEGA, vtVGA, vtOlder);

const

        CurrentFontBank : Byte = 0;     { current font bank we programming }
        BankIncrement   = 16384;        { size of font bank in bytes }

        CurX     : Word = 0;            { current X position }
        CurY     : Word = 0;            { current Y position }
        C1Char   : Word = $C6;          {'Þ'}{ character to use as #1 }
        C2Char   : Word = $C7;          {'Ý'}{ --"-- #2 }
        C3Char   : Word = $D7;          {'×'}{ --"-- #3 }
        C4Char   : Word = $D8;          {'Ø'}{ __"__ #4 }
        C1       : array[1..16] of Byte = (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0);
        C2       : array[1..16] of Byte = (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0);
        C3       : array[1..16] of Byte = (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0);
        C4       : array[1..16] of Byte = (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0);
        Visible  : Boolean = False;     { mouse pointer is visible }
        ModeFlip : Boolean = False;     { using 8 pixel-wide chars }
        VidType  : VideoType = vtVGA;   { video adapter in use }
{$IFDEF TrackVideoMode}
        InvalidMode: Boolean = False;   { invalid screen mode - operation
                                          suspended }
{$ENDIF}
        SaveBuf  : array[1..32] of Word = (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
                                           0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0);
        OldChars : array[1..4] of Byte = (0,0,0,0);
        OldPos   : Word = 0;
        OldEvents: Word = 0;            { holds old event mask }

        OldHandler : Pointer = nil;     { holds address of old mouse handler }
        i33Handler : Pointer = nil;     { holds address of INT 33 handler }
        YSize    : Word = 394;          { Window max Y }
        YMax     : Word = 394;          { Y max }
        XSize    : Word = 638;          { Window max X }
        XMin     : Word = 0;            { Window min X }
        YMin     : Word = 0;            { Window min Y }
    InTwoFontMode: Boolean = False;     { two different fonts are displayed
                                          simultaneously }
        Bank1    : Byte = 0;            { font bank 1 }
        Bank2    : Byte = 1;            { font bank 2 }

        ORMask   : array[1..16] of Byte =
                   ($00,$40,$60,$70,$78,$7C,$7E,$7F,$7C,$4C,$0E,$06,$06,$00,$00,$00);

        ANDMask  : array[1..16] of Byte =
                   ($3F,$1F,$0F,$07,$03,$01,$00,$00,$00,$01,$21,$F0,$F0,$F0,$FF,$FF);


procedure setFontMode;
 begin
  InTwoFontMode := TwoFonts;
  Bank1 := fontBank1;
  Bank2 := fontBank2;
 end;

procedure setDisplayableFonts; assembler;
{ makes call to video BIOS character generator function 1103h. BL contains
  two font values in six lower bits: 212211, where 1 is bit of first font value
  and 2 - of second. }
asm
        mov     bl,Font2
        shl     bl,3
        and     bl,20h
        mov     al,Font2
        and     al,3
        shl     al,2
        or      bl,al
        mov     al,Font1
        and     al,4
        shl     al,2
        or      bl,al
        mov     al,Font1
        and     al,3
        or      bl,al
        mov     ax,1103h
        int     10h
end;

procedure Mode8BPC; near; assembler;
{ set 8 pixel-wide characters mode on VGA systems }
asm
        cmp     VidType,vtVGA
        jnz     @@Q
        cli
        mov     dx,3C4h
        mov     al,1
        out     dx,al
        inc     dx
        in      al,dx
        or      al,1

        out     dx,al
        mov     dx,3CCh
        in      al,dx
        and     al,0F3h

        mov     dx,3C2h
        out     dx,al
        mov     dx,3DAh
        in      al,dx
        mov     dx,3C0h
        mov     al,13h
        out     dx,al
        sub     al,al
        out     dx,al
        mov     al,20h
        out     dx,al
        sti
        mov     byte ptr C1Char,1
        mov     byte ptr C2Char,2
        mov     byte ptr C3Char,13
        mov     byte ptr C4Char,10
@@Q:
end;

procedure Mode9BPC; near; assembler;
{ set 9 pixel-wide character mode on VGA systems }
asm
        cmp     VidType,vtVGA
        jnz     @@Q
        cli
        mov     dx,3C4h
        mov     al,1
        out     dx,al
        inc     dx
        in      al,dx
        and     al,0FEh
        out     dx,al
        mov     dx,3CCh
        in      al,dx
        and     al,0F3h
        or      al,4
        mov     dx,3C2h
        out     dx,al
        mov     dx,3DAh
        in      al,dx
        mov     dx,3C0h
        mov     al,13h
        out     dx,al
        sub     al,al
        dec     al
        out     dx,al
        mov     al,20h
        out     dx,al
        sti
@@Q:
end;

procedure GetNewPos; near; forward;
procedure gShowMouse; near; forward;
procedure gHideMouse; near; forward;


procedure MouseHandler; far; assembler;
{ this handler is called whenever something happen to mouse (it was moved,
  clicked, etc. }
asm
        push    seg @data
        pop     ds
        test    ax,1            { was it movement? }
        jz      @@oldh          { no - then we don't care }
        pusha
        mov     al,Visible      { save visibility }
        push    ax
        call    gHideMouse      { hide mouse }
        call    GetNewPos       { compute new pointer position }
        pop     ax
        or      al,al           { was pointer visible? }
        jz      @@2
        call    gShowMouse      { put it back on screen }
@@2:
        popa
@@oldh:
        push    ax
        mov     ax,CurY
        cwd
        div     CharSize
        shl     ax,3
        mov     dx,ax
        mov     cx,CurX
        and     cl,0F8h
        and     dl,0F8h
        pop     ax
        and     ax,OldEvents    { let previous handler to handle only his events }
{$IFDEF TrackVideoMode}
        push    cx
        push    dx
{$ENDIF}
        jz      @@Q             { no events left for previous handler? }
        push    si
        mov     si, word ptr OldHandler
        or      si, word ptr OldHandler[2]
        pop     si
        jz      @@Q
        call    dword ptr ds:[OldHandler]
        jmp     @@Q
        db      13,10
        db      'g_Mouse Interface  Version 1.53.7  Copyright(c) 1993-96 by B-coolWare.'
        db      13,10
@@Q:
{$IFDEF TrackVideoMode}
        pop     dx
        pop     cx
        cmp     InvalidMode,1
        jnz     @@exit
        mov     ax,4
        pushf
        call    dword ptr [i33Handler]  { we're still tracking mouse movement
                                          so we should let driver know where
                                          the pointer should really be }
@@exit:
{$ENDIF}
end;

procedure SetupRWMode; near; assembler;
{ set up character generator character map read/write mode }
asm
        push    ax
        push    dx
        mov     dx,3C4h
        mov     ax,0402h
        out     dx,ax
        mov     ax,0704h
        out     dx,ax
        mov     dl,0CEh
        mov     ax,0005h
        out     dx,ax
        mov     ax,0406h
        out     dx,ax
        mov     ax,0204h
        out     dx,ax
        pop     dx
        pop     ax
end;

procedure CloseRWMode; near; assembler;
{ reset video memory to normal text mode operation }
asm
        push    ax
        push    dx
        mov     dx,3C4h
        mov     ax,0302h
        out     dx,ax
        mov     ax,0304h
        out     dx,ax
        mov     dl,0CEh
        mov     ax,1005h
        out     dx,ax
        mov     ax,0E06h
        out     dx,ax
        mov     ax,0004h
        out     dx,ax
        pop     dx
        pop     ax
end;

procedure MoveChar; near; assembler;
{ copy cx words to/from video memory }
asm
        call    SetupRWMode
        rep     movsw
        call    CloseRWMode
end;

procedure LoadChar; near; assembler;
{ read character map from video memory, es:di points to buffer }
asm
        push    cx
        shl     si,5
        push    cx
        push    ds
        push    seg CurrentFontBank
        pop     ds
        mov     cl,CurrentFontBank
        sub     ch,ch
        cmp     VidType,vtEGA
        jz      @@100
        cmp     cl,4
        jb      @@100
        add     si,8192
@@100:
        jcxz    @@1
@@2:
        add     si,BankIncrement
        loop    @@2
@@1:
        pop     ds
        pop     cx
        call    MoveChar
        pop     cx
end;

procedure SaveChar; near; assembler;
{ write character map to video memory, ds:si points to source }
asm
        push    cx
        shl     di,5
        push    cx
        push    ds
        push    seg CurrentFontBank
        pop     ds
        mov     cl,CurrentFontBank
        sub     ch,ch
        cmp     VidType,vtEGA
        jz      @@100
        cmp     cl,4
        jb      @@100
        add     di,8192
@@100:
        jcxz    @@1
@@2:
        add     di,BankIncrement
        loop    @@2
@@1:
        pop     ds
        pop     cx
        call    MoveChar
        pop     cx
end;

procedure LoadChars( Ch1, Ch2, Ch3, Ch4 : Word ); near; assembler;
{ read our four character maps from video memory }
asm
        push    ds

        push    seg C1
        pop     es

        mov     cx,CharSize
        shr     cx,1
        push    SegA000
        pop     ds

        cld

        mov     di,offset C1
        mov     si,Ch1
        and     si,0FFh
        call    LoadChar

        mov     di,offset C2
        mov     si,Ch2
        and     si,0FFh
        call    LoadChar

        mov     di,offset C3
        mov     si,Ch3
        and     si,0FFh
        call    LoadChar

        mov     di,offset C4
        mov     si,Ch4
        and     si,0FFh
        call    LoadChar

        pop     ds
end;

procedure SaveChars( Ch1, Ch2, Ch3, Ch4 : Word ); near; assembler;
{ store our character maps in video memory }
asm
        push    seg @data
        pop     ds

        mov     cx,CharSize
        shr     cx,1
        push    SegA000
        pop     es

        cld

        mov     si,offset C1
        mov     di,Ch1
        and     di,0FFh
        call    SaveChar

        mov     si,offset C2
        mov     di,Ch2
        and     di,0FFh
        call    SaveChar

        mov     si,offset C3
        mov     di,Ch3
        and     di,0FFh
        call    SaveChar

        mov     si,offset C4
        mov     di,Ch4
        and     di,0FFh
        call    SaveChar
end;

procedure computeOffset; near; assembler;
{ computes offset of character at (CurX,CurY) in video buffer }
asm
        push    ax
        push    bx
        push    dx
        mov     si,CurX
        shr     si,2
        mov     ax,CurY
        cwd
        mov     bx,CharSize
        div     bx
        mov     bl,160
        mul     bl
        add     si,ax
        and     si,0FFFEh
        pop     dx
        pop     bx
        pop     ax
end;

procedure UpdateChars; near; assembler;
{ applies -and- and -or- masks on characters behind cursor to make it visible }
asm
        call    computeOffset
        push    SegB800
        pop     es
        push    word ptr es:[si]
        push    word ptr es:[si+2]
        push    word ptr es:[si+160]
        push    word ptr es:[si+162]
        call    LoadChars
        mov     cx,CurX
        mov     bx,CurY
        and     cx,7
        mov     ax,CharSize
        dec     ax
        and     bx,ax
        sub     si,si
@@1:
        cmp     bx,CharSize
        jz      @@2
        mov     ah, byte ptr C1[bx]
        mov     al, byte ptr C2[bx]
        mov     dh, byte ptr ANDMask[si]
        mov     dl,0FFh
        ror     dx,cl
        and     ax,dx
        mov     dh, byte ptr ORMask[si]
        sub     dl,dl
        shr     dx,cl
        or      ax,dx
        mov     byte ptr C1[bx],ah
        mov     byte ptr C2[bx],al
        inc     bx
        inc     si
        cmp     si,CharSize
        jb      @@1
        jmp     @@3
@@2:
        sub     bx,bx
@@4:
        mov     ah,byte ptr C3[bx]
        mov     al,byte ptr C4[bx]
        mov     dh,byte ptr ANDMask[si]
        mov     dl,0FFh
        ror     dx,cl
        and     ax,dx
        mov     dh,byte ptr ORMask[si]
        sub     dl,dl
        shr     dx,cl
        or      ax,dx
        mov     byte ptr C3[bx],ah
        mov     byte ptr C4[bx],al
        inc     bx
        inc     si
        cmp     si,CharSize
        jb      @@4
@@3:
        push    C1Char
        push    C2Char
        push    C3Char
        push    C4Char
        call    SaveChars
end;

procedure GetNewPos; assembler;
{ get new pointer position in mickeys (we using them instead of pixels) }
asm
        mov     ax,0Bh
        int     33h
        add     CurX,cx
        add     CurY,dx
        mov     ax,CurX
        or      ax,ax
        js      @@6
        cmp     ax,XMin
        jnb     @@1
@@6:
        mov     ax,XMin
        jmp     @@2
@@1:
        cmp     ax,XSize
        jbe     @@2
        mov     ax,XSize
@@2:
        mov     CurX,ax
        mov     ax,CurY
        or      ax,ax
        js      @@5
        cmp     ax,YMin
        jnb     @@3
@@5:
        mov     ax,YMin
        jmp     @@4
@@3:
        cmp     ax,YSize
        jbe     @@4
        mov     ax,YSize
@@4:
        mov     CurY,ax
end;

procedure gShowMouse; assembler;
{ show mouse pointer }
asm
        cmp     Active,0        { g_Mouse system active? }
        jz      @@Q
        cmp     Visible,1       { already visible? }
        jz      @@Q
        push    ax
        push    si
        push    es
        call    computeOffset
        mov     OldPos,si
        push    SegB800
        pop     es
        mov     al,es:[si]
        mov     byte ptr OldChars,al
        mov     al,es:[si+2]
        mov     byte ptr OldChars[1],al
        mov     al,es:[si+160]
        mov     byte ptr OldChars[2],al
        mov     al,es:[si+162]
        mov     byte ptr OldChars[3],al
        cmp     InTwoFontMode,1
        jnz     @@100   { don't care about CurrentFontBank - it's always 0 }
        mov     al,CurrentFontBank
        push    ax
        mov     al,Bank1
        mov     CurrentFontBank,al
@@100:                  { update both used fonts }
        push    es
        push    si
        call    UpdateChars
        pop     si
        pop     es
        cmp     InTwoFontMode,1 { are there two fonts on screen? }
        jnz     @@done          { nope - we're quit then }
        mov     al,Bank2        { else update characters in second used font }
        mov     CurrentFontBank,al
        push    es
        push    si
        call    UpdateChars
        pop     si
        pop     es
        pop     ax
        mov     CurrentFontBank,al
@@done:
        mov     al,byte ptr C1Char
        mov     ah,byte ptr C3Char
        mov     es:[si],al
        mov     es:[si+160],ah
        cmp     CurX,632
        jae     @@10            { oops! wrapping may occur }
        mov     al,byte ptr C2Char
        mov     ah,byte ptr C4Char
        mov     es:[si+2],al
        mov     es:[si+162],ah
@@10:
        pop     es
        pop     si
        pop     ax
        mov     Visible,1       { signal that pointer is now visible }
@@Q:
end;

procedure gHideMouse; assembler;
{ hide mouse pointer }
asm
        cmp     Active,0        { g_Mouse system active? }
        jz      @@Q
        cmp     Visible,0       { already hidden? }
        jz      @@Q
        push    ax
        push    es
        push    di
        mov     di,OldPos
        push    SegB800
        pop     es
        mov     al,byte ptr OldChars
        mov     es:[di],al
        mov     al,byte ptr OldChars[1]
        mov     es:[di+2],al
        mov     al,byte ptr OldChars[2]
        mov     es:[di+160],al
        mov     al,byte ptr OldChars[3]
        mov     es:[di+162],al
        pop     di
        pop     es
        pop     ax
        mov     Visible,0       { signal that pointer is hidden }
@@Q:
end;

function isVGAble : Boolean; near; assembler;
{ check whether current video adapter a VGA/EGA }
asm
        mov     ax,1A00h
        int     10h
        cmp     al,1Ah
        jz      @@Ok
        push    es              { still keeping compatibility with EGA systems }
        push    Seg0040         { though they're very rare now... }
        pop     es
        mov     al,es:[87h]
        pop     es
        or      al,al
        jz      @@Fail          { this is even not EGA! }
        mov     VidType,vtEGA
        mov     CharSize,14     { EGA's text display is 640x350 pixels, }
        mov     YSize,344       { characters are 14 lines high }
        mov     YMax,344
@@Ok:
        mov     al,1            { Return TRUE }
        jmp     @@Q
@@Fail:
        sub     al,al           { Return FALSE }
        mov     VidType,vtOlder
@@Q:
end;

{$IFDEF TrackVideoMode}
procedure checkMode; near; assembler;
{ check if video mode is appropriate for g_Mouse operation }
asm
        push    ax
        push    bx
        push    cx
        push    dx
        push    si
        push    di
        push    es
        push    bp
        mov     ah,0Fh
        int     10h
        cli
        cmp     al,3
        jnz     @@fail
        cmp     ah,80
        jb      @@fail
        mov     ax,1130h
        int     10h
        cli
        cmp     dl,30
        jbe     @@ok
@@fail:
        mov     InvalidMode,1
        mov     CharSize,8
        stc
        jmp     @@Q
@@ok:
        cmp     InvalidMode,1
        jnz     @@2
        mov     CharSize,16
        cmp     VidType,vtVGA
        jz      @@3
        mov     CharSize,14
@@3:
        mov     InvalidMode,0
        cmp     ModeFlip,1
        jnz     @@2
        call    Mode8BPC
@@2:
        clc
@@Q:
        pop     bp
        pop     es
        pop     di
        pop     si
        pop     dx
        pop     cx
        pop     bx
        pop     ax
end;
{$ENDIF}

procedure MouseInt; assembler;
asm
        push    ds
        push    seg @data
        pop     ds
{$IFDEF TrackVideoMode}
        call    checkMode
        jc      @@JOld
{$ENDIF}
        cmp     Active,0
        jz      @@JOld
        cmp     ax,1    { show mouse pointer }
        jz      @@1
        cmp     ax,2    { hide mouse pointer }
        jz      @@2
        cmp     ax,3    { get current pointer coordinates (in pixels) }
        jz      @@3
        cmp     ax,4    { set current pointer coordinates }
        jz      @@4
        cmp     ax,7    { set horizontal clipping boundaries }
        jz      @@7
        cmp     ax,8    { set vertical clipping boundaries }
        jz      @@8
        cmp     ax,0Ch  { set new event handler }
        jz      @@0C
        cmp     ax,14h  { exchange handlers - doesn't work in PM }
        jz      @@14

        { set mouse+key handler, get mouse+key handler and other functions are
          not intercepted for they are used very rarely. }
@@JOld:

       (* because in PM we can't write to code segment without getting code
          segment alias, I do not use here more convenient way to chain to
          previous interrupt handler:

          DB    0EAh    { far jump [immediate] opcode }
          DD    SaveIntVector

          because it leads to some difficulties in PM. Usually in Pascal I
          do it this way:

          Because there is no way in pascal to make SaveIntVector global, I
          add one function to handle, which takes one parameter - dword to
          write to SaveIntVector, and do an explicit call to handler with
          value of current interrupt vector somewhere on program startup.
       *)

        pushf
        call    dword ptr [i33Handler]
        pop     ds
        iret
@@1:
        call    gShowMouse
        jmp     @@out
@@2:
        call    gHideMouse
        jmp     @@out
@@3:

        pushf
        call    dword ptr [i33Handler] { simulating interrupt }
        push    ax
        mov     ax,CurY         { substituting mouse driver's coordinates with
                                  ours }
        cwd
        div     CharSize
        shl     ax,3
        mov     cx,CurX
        mov     dx,ax
        and     cl,0F8h
        and     dl,0F8h
        pop     ax
        jmp     @@out
@@4:
        mov     CurX,cx
        push    dx
        shr     dx,3
        push    ax
        mov     ax,dx
        mul     byte ptr CharSize
        mov     CurY,ax
        pop     ax
        pop     dx
        jmp     @@out
@@7:
        mov     XMin,cx
        cmp     dx,638
        jb      @@71
        mov     dx,638
@@71:
        mov     XSize,dx
        jmp     @@out
@@8:
        push    ax
        mov     ax,cx
        shr     ax,3
        mul     byte ptr CharSize
        mov     YMin,ax
        mov     ax,dx
        shr     ax,3
        mul     byte ptr CharSize
        cmp     ax,YMax
        jae     @@81
        push    ax
        add     ax,16
        cmp     ax,YMax
        pop     ax
        jae     @@81
        mov     YSize,ax
@@81:
        pop     ax
        jmp     @@out
@@0C:
        mov     word ptr OldEvents,cx           { setting new handler address }
        mov     word ptr OldHandler,dx          { we'll chain to }
        mov     word ptr OldHandler[2],es
        jmp     @@out
@@14:
        push    ax
        xchg    cx,OldEvents
        xchg    word ptr OldHandler,dx
        mov     ax,es
        xchg    word ptr OldHandler[2],ax
        mov     es,ax
        pop     ax
@@out:
        pop     ds
        iret
end;

procedure initGMouse;
{ initialize graphical mouse pointer system }
label Failed, InvMode;
 begin
  if Active then
   DoneGMouse;
  asm
        { check if mouse driver present and is operatable }
        mov     ax,3533h
        int     21h
        mov     ax,es
        or      ax,bx
        jz      Failed
        sub     ax,ax
        int     33h
        or      ax,ax
        jz      Failed
  end;
  if not isVGAble then
 Failed:
   exit;
  asm
{$IFDEF TrackVideoMode}
        mov     InvalidMode,1
{$ENDIF}
        mov     ah,0Fh
        int     10h
        cmp     al,3
        jnz     InvMode
        cmp     ah,80
        jb      InvMode
{$IFDEF TrackVideoMode}
        mov     InvalidMode,0
{$ENDIF}
   end;
  if FlipMode then
   Mode8BPC;
  ModeFlip := FlipMode;
  LoadChars(C1Char, C2Char, C3Char, C4Char);
  Move(C1,SaveBuf,sizeof(SaveBuf));
 InvMode:
  asm
        mov     ax,0Ch
        push    cs
        pop     es
        mov     dx,offset MouseHandler
        mov     cx,7Fh
        int     33h
  { in above code I use the fact that Borland's DPMI host translates the 0Ch
    mouse function properly, so I don't have to manually allocate the callback
    for MouseHandler and all that stuff - DPMI host does this itself, which is
    really kind for Borland. }
  end;
  GetIntVec($33,i33Handler);
  SetIntVec($33,@MouseInt);
  Active := True;
 end;

procedure doneGMouse;
{ deinitialize graphical mouse pointer system }
 begin
  if not Active then
   exit;
  SetIntVec($33,i33Handler);
  gHideMouse;
  Move(SaveBuf,C1,sizeof(SaveBuf));
  SaveChars(C1Char, C2Char, C3Char, C4Char);
  if ModeFlip then
   Mode9BPC;
  asm
        mov     ax,0Ch
        mov     cx,[OldEvents]
        mov     dx,word ptr [OldHandler][2]
        mov     es,dx
        mov     dx,word ptr [OldHandler]
        int     33h
  end;
  C1Char := $DE; {'Þ'}
  C2Char := $DD; {'Ý'}
  C3Char := $D7; {'×'}
  C4Char := $D8; {'Ø'}
  Active := False;
 end;

procedure setMouseChars;
 begin
  if Active then
   begin
    Move(SaveBuf,C1,sizeof(SaveBuf));
    SaveChars(C1Char, C2Char, C3Char, C4Char);
   end;
  C1Char := C1Code;
  C2Char := C2Code;
  C3Char := C3Code;
  C4Char := C4Code;
  if Active then
   begin
    LoadChars(C1Char, C2Char, C3Char, C4Char);
    Move(C1,SaveBuf,sizeof(SaveBuf));
   end;
 end;


procedure getPointerShape;
 begin
  Move(ANDMask, AND_Mask, CharSize);
  Move(ORMask, OR_Mask, CharSize);
 end;

procedure setPointerShape;
 var SVisible : Boolean;
 begin
  SVisible := Visible;
  if Active then
   gHideMouse;
  Move(AND_Mask, ANDMask, CharSize);
  Move(OR_Mask,ORMask, CharSize);
  if Active and SVisible then
   gShowMouse;
 end;

procedure getCharBitmap; assembler;
{ read character bitmap from VRAM. Does not read character if it is used for
  mouse pointer }
asm
        mov     si,C
        cmp     si,C1Char
        jz      @@fill0
        cmp     si,C2Char
        jz      @@fill0
        cmp     si,C3Char
        jz      @@fill0
        cmp     si,C4Char
        jz      @@fill0
        shl     si,5
        mov     cl,CurrentFontBank
        sub     ch,ch
        cmp     VidType,vtEGA
        jz      @@100
        cmp     cl,4
        jb      @@100
        add     si,8192
@@100:
        jcxz    @@copy
@@lp:
        add     si,BankIncrement
        loop    @@lp
@@copy:
        mov     cl,16
        push    ds
        push    SegA000
        pop     ds
        les     di,Bitmap
        cld
        call    MoveChar
        pop     ds
        jmp     @@Q
@@fill0:
        cld
        les     di,Bitmap
        sub     ax,ax
        mov     cx,16
        rep     stosw
@@Q:
end;

procedure setCharBitmap; assembler;
{ writes character bitmap to VRAM. Does not change character if it is used for
  mouse pointer }
asm
        mov     al,Visible
        push    ax
        cmp     Active,0
        jz      @@1
        call    gHideMouse
@@1:
        mov     di,C
        cmp     di,C1Char
        jz      @@skip
        cmp     di,C2Char
        jz      @@skip
        cmp     di,C3Char
        jz      @@skip
        cmp     di,C4Char
        jz      @@skip
        shl     di,5
        mov     cl,CurrentFontBank
        sub     ch,ch
        cmp     VidType,vtEGA
        jz      @@100
        cmp     cl,4
        jb      @@100
        add     di,8192
@@100:
        jcxz    @@copy
@@lp:
        add     di,BankIncrement
        loop    @@lp
@@copy:
        mov     cl,16
        push    SegA000
        pop     es
        push    ds
        lds     si,Bitmap
        cld
        call    MoveChar
        pop     ds
@@skip:
        pop     ax
        or      al,al
        jz      @@Q
        cmp     Active,0
        jz      @@Q
        call    gShowMouse
@@Q:
end;

const
        Vga30Lines: array[0..14] of word =
          ($0100, $0001, $0302, $0003, $0204, $0300, $0C11,
           $0B06, $3E07, $4F09, $EA10, $8C11, $DF12, $E715, $0416);

procedure set30Lines; assembler;
{ set 30x85 video mode }
asm
     lea     si,Vga30Lines

     mov     dx,03C4h
     mov     cx,5
     cld
@@1: lodsw
     out     dx,ax
     loop    @@1

     mov     dl,0C2h
     mov     al,0E7h
     out     dx,al
     mov     dl,0C4h
     lodsw

     out     dx,ax
     mov     dl,0D4h
     mov     cx,9
@@2: lodsw
     out     dx,ax
     loop    @@2

     mov     ax,Seg0040
     mov     es,ax
     mov     byte ptr es:[84h],29
     and     byte ptr es:[87h],not 1
     mov     byte ptr es:[49h],3
     mov     word ptr es:[4Ch],12C0h
     mov     YSize,474
     mov     YMax,474
@@Exit:
end;

procedure selectFontBank;
{ selects font bank to be used by subsequent font programming calls }
 begin
  if VidType = vtVGA then
   CurrentFontBank := FontBank
  else
   CurrentFontBank := FontBank and 3; { EGA supports only banks 0 thru 3 }
 end;

const

     OldExitProc : Pointer = nil;

procedure gMouseExitProc; far;
{ exit procedure. Called on program shutdown automatically by Pascal's RTL }
 begin
  ExitProc := OldExitProc;
  DoneGMouse;
 end;

begin
 OldExitProc := ExitProc;
 ExitProc := @gMouseExitProc;
 InitGMouse(False);
end.
