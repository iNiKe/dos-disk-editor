{$A-}
unit mcp_cd;
interface
         type letters=array [1..10] of byte;
              aud_chnl=record
                   chn1:byte;
                   vol1:byte;
                   chn2:byte;
                   vol2:byte;
                   chn3:byte;
                   vol3:byte;
                   chn4:byte;
                   vol4:byte;
              end;
              aud_Qchnl=record
                   adr:byte; { режим адресации      }
                   num:byte; { номер дорожки        }
                   ind:byte; { point или индекс     }
                  wmin:byte; { время внутри дорожки }
                  wsec:byte;
                  wfrm:byte;
                  wzer:byte;
                  dmin:byte; { время на диске }
                  dsec:byte;
                  dfrm:byte;
              end;
              aud_disk=record
                    low:byte;
                   high:byte;
                  start:longint;
              end;
              aud_track=record
                  start:longint;
                   info:byte;
                end;
              aud_stat=record
                  stat:word;
             start_pos:longint;
               end_pos:longint;
                   end;
                UPC=record
                   adr:byte;
                  code:array[1..13] of byte;
                  zero:byte;
                   frm:byte;
                   end;

                  READ=record
                   am:byte;    { режим интерпретации адреса           }
                  adr:pointer; { адрес буфера                         }
                  num:word;    { количество секторов для считывания   }
                start:longint; { номер начального сектора             }
                   rm:byte;    { режим считывания 0 - cooked, 1 - raw }
             int_size:byte;    { interliave size                      }
             int_skip:byte;    { interleave skip factor               }
                      end;

                song=record
                 num:byte;    { номер дорожки }
               start:longint; { нач. адрес в виде RED BOOK }
              length:longint; { длина в виде RED BOOK }
                     end;

         var      cd_num:byte;
              cd_letters:letters;
{******************* ФУНКЦИИ ДЛЯ УДОБСТВА ****************}
procedure cdrom_upc_string(var code:upc;var s:string);
procedure cdrom_redbook_sector(rb:longint;var sect:longint);
procedure cdrom_sector_redbook(sect:longint;var rb:longint);
function cdrom_song_info(num:byte;adr:pointer;var k:byte):byte;
{******************* ФУНКЦИИ ДРАЙВЕРА ********************}
{ IOCTL Input }
function cdrom_device_header(num:byte;var adr:pointer):byte;
function cdrom_head_location(num,adr:byte;var pos:longint):byte;
function cdrom_AudChnl_info(num:byte;var a:aud_chnl):byte;
{function cdrom_readdrv_bytes(num:byte;var adr:pointer):byte;}
function cdrom_device_status(num:byte;var stat:longint):byte;
function cdrom_sector_size(num,adr:byte;var size:word):byte;
function cdrom_volume_size(num:byte;var size:longint):byte;
function cdrom_media_changed(num:byte;var m:byte):byte;
function cdrom_AudDisk_info(num:byte;var a:aud_disk):byte;
function cdrom_AudTrack_info(num,n:byte;var a:aud_track):byte;
function cdrom_AudQChnl_info(num:byte;var a:aud_Qchnl):byte;
function cdrom_AudSubChnl_info(num:byte;start,n:longint;adr:pointer):byte;
function cdrom_upccode_read(num:byte;var code:upc):byte;      { may be not supported }
function cdrom_AudStat_read(num:byte;var s:Aud_stat):byte;
{ IOCTL Output }
function cdrom_open_tray(num:byte):byte;
function cdrom_close_tray(num:byte):byte;
function cdrom_lock_door(num:byte):byte;
function cdrom_unlock_door(num:byte):byte;
function cdrom_reset(num:byte):byte;
function cdrom_AudChnl_ctrl(num:byte;var a:aud_chnl):byte;
{ READ LONG +READ LONG PREFETCH }
function cdrom_readlong(num:byte;var adr:read):byte;
function cdrom_readlong_prefetch(num:byte;var adr:read):byte; { may be not supported }
{ SEEK }
function cdrom_seek(num,adr:byte;pos:longint):byte;
{ PLAY AUDIO }
function cdrom_audplay(num,adr:byte;start,n:longint):byte;
{ STOP AUDIO }
function cdrom_audstop(num:byte):byte;
{ RESUME AUDIO }
function cdrom_audresume(num:byte):byte;
{ INPUT FLUSH }
function cdrom_inputflush(num:byte):byte;
{ DEVICE OPEN/CLOSE }
function cdrom_device_open(num:byte):byte;
function cdrom_device_close(num:byte):byte;


implementation
              var hdr:word;
                  hdr_present:boolean;
{
*********************************************************
 ПРЕОБРАЗОВАНИЕ UPC В STRING
*********************************************************
}
        procedure cdrom_upc_string(var code:upc;var s:string);
              var i,k:byte;
                  begin
                  s:='';
                  for i:=1 to 13 do
                  begin
                  k:=code.code[i];
                  if k>9 then k:=k+7;
                  k:=k+$30;
                  s:=s+chr(k);
                  end;
                  end;

{
*********************************************************
 РЕЗЕРВИРУЕМ HEADER
  n - число параграфов
*********************************************************
}
              function make_hdr(n:byte):byte;assembler;
                       asm
                       push bx
                       mov bl,n
                       mov bh,0
                       mov ah,48h
                       int 21h
                       jc @e1
                       mov word ptr hdr,ax
                       mov byte ptr hdr_present,1
                       xor ax,ax
                       jmp @er
                   @e1:mov ax,1
                   @er:pop bx
                       end;
{
*********************************************************
 Вызываем Request Device
 n - номер cd в массиве cd_letters
*********************************************************
}
              function request(n:byte):word;assembler;
                        asm
                        push bx
                        push cx
                        push es
                        mov ax,seg @data
                        mov es,ax
                        mov bx,offset cd_letters
                        add bl,n
                        adc bh,0
                        dec bx
                        mov cl,byte ptr [es:bx]
                        mov ch,0
                        mov bx,word ptr hdr
                        mov es,bx
                        xor bx,bx
                        mov ax,1510h
                        int 2fh
                        mov ax,word ptr es:[bx+3]
                        pop es
                        pop cx
                        pop bx
                        end;
{
*********************************************************
 ПРОВЕРКА НАЛИЧИЯ CDROMов
*********************************************************
}

              function cdrom_check:byte;assembler;
                       asm
                       push bx
                       push cx
                       push es
                       push ds
                       push si
                       push di
                       pushf
                       mov ax,1500h
                       int 2fh
                       { bx - число CD драйвов }
                       or bx,bx
                       jz @e1
                       push  bx
                       mov cl,4
                       shr bx,cl
                       inc bx
                       mov ah,48h
                       int 21h
                       { ax - адрес памяти }
                       jc @e2
                       push ax
                       mov es,ax
                       xor bx,bx
                       mov ax,150dh
                       int 2fh
                       { в буфере буквы }
                       mov ax,seg @data
                       mov es,ax
                       mov di,offset cd_letters
                       xor si,si
                       pop dx
                       { dx - сегментный адрес буфера }
                       pop cx
                       { cx - число CD }
                       push cx
                       push ds
                       mov ds,dx
                       cld
                       rep movsb
                       pop ds
                       mov es,dx
                       mov bx,dx
                       mov ah,49h
                       int 21h
                       pop cx
                       mov byte ptr cd_num,cl
                       xor ax,ax
                       jmp @er
                   @e1:mov ax,80h
                       jmp @er
                   @e2:pop bx
                       mov ax,1
                   @er:popf
                       pop di
                       pop si
                       pop ds
                       pop es
                       pop cx
                       pop bx
                       end;
{
*********************************************************
 CDROM IOCTL INPUT
  n - номер CD драйва ( от 1 ) из массива
  adr - указатель в памяти на управляющий блок
  num - количество байт для считывания
  com - код команды ( 3 - для вввода ) 12 - вывод
*********************************************************
}

          function cdrom_ioctl(n:byte;adr:pointer;num,com:byte):byte;assembler;
                       asm
                       push bx
                       push es
                       mov al,n
                       mov ah,cd_num
                       cmp al,ah
                       ja @e1
                       mov al,hdr_present
                       or al,al
                       jz @e2
                       mov ax,word ptr hdr
                       mov es,ax
                       xor bx,bx
                       { es:bx - память заголовка }
                       mov byte ptr es:[bx],26
                       mov byte ptr es:[bx+1],0
                       mov al,byte ptr com
                       mov byte ptr es:[bx+2],al
                       mov byte ptr es:[bx+13],0
                       mov ax,word ptr [adr]
                       mov word ptr es:[bx+14],ax
                       mov ax,word ptr [adr+2]
                       mov word ptr es:[bx+16],ax
                       mov al,num
                       mov ah,0
                       mov word ptr es:[bx+18],ax
                       xor ax,ax
                       mov word ptr es:[bx+20],ax
                       mov word ptr es:[bx+22],ax
                       mov word ptr es:[bx+24],ax
                       mov al,n
                       mov ah,0
                       push ax
                       call request
                       test ah,80h
                       jz @er
                   @e3:add al,83h
                       jmp @er
                   @e2:mov al,82h
                       jmp @er
                   @e1:mov al,81h
                       jmp @er
                   @er:mov ah,0
                       pop es
                       pop bx
                       end;

{
*********************************************************
 ПОЛУЧАЕМ АДРЕС ЗАГОЛОВКА ДРАЙВЕРА
  num - номер CD драйва ( от 1 ) из массива
*********************************************************
}

          function cdrom_device_header(num:byte;var adr:pointer):byte;assembler;
                       asm
                       jmp @l0
                   @cb:db 0
                       dd 0
                   @l0:mov al,num
                       mov ah,0
                       push ax
                       mov ax,cs
                       push ax
                       mov ax,offset cs:[@cb]
                       push ax
                       mov ax,5
                       push ax
                       mov ax,3
                       push ax
                       call cdrom_ioctl
                       or ax,ax
                       jnz @er
                       push bx
                       push es
                       les bx,adr
                       mov ax,word ptr cs:[@cb+1]
                       mov word ptr es:[bx],ax
                       mov ax,word ptr cs:[@cb+3]
                       mov word ptr es:[bx+2],ax
                       pop es
                       pop bx
                       xor ax,ax
                   @er:
                       end;
{
*********************************************************
 ПОЛУЧАЕМ МЕСТОПОЛОЖЕНИЕ ГОЛОВКИ
  num - номер CD драйва ( от 1 ) из массива
*********************************************************
}

          function cdrom_head_location(num,adr:byte;var pos:longint):byte;assembler;
                       asm
                       jmp @l0
                   @cb:db 1
                       db 0
                       dd 0
                   @l0:mov al,adr
                       mov byte ptr cs:[@cb+1],al
                       mov al,num
                       mov ah,0
                       push ax
                       mov ax,cs
                       push ax
                       mov ax,offset cs:[@cb]
                       push ax
                       mov ax,6
                       push ax
                       mov ax,3
                       push ax
                       call cdrom_ioctl
                       or ax,ax
                       jnz @er
                       push bx
                       push es
                       les bx,pos
                       mov ax,word ptr cs:[@cb+2]
                       mov word ptr es:[bx],ax
                       mov ax,word ptr cs:[@cb+4]
                       mov word ptr es:[bx+2],ax
                       pop es
                       pop bx
                       xor ax,ax
                   @er:
                       end;
{
*********************************************************
 ПОЛУЧАЕМ ИНФОРМАЦИЮ ОБ АУДИОКАНАЛАХ
  num - номер CD драйва ( от 1 ) из массива
*********************************************************
}

              function cdrom_audchnl_info(num:byte;var a:aud_chnl):byte;assembler;
                       asm
                       jmp @l0
                   @cb:db 4
                       dd 0
                       dd 0
                   @l0:mov al,num
                       mov ah,0
                       push ax
                       mov ax,cs
                       push ax
                       mov ax,offset cs:[@cb]
                       push ax
                       mov ax,9
                       push ax
                       mov ax,3
                       push ax
                       call cdrom_ioctl
                       or ax,ax
                       jnz @er
                       push bx
                       push es
                       les bx,a
                       mov ax,word ptr cs:[@cb+1]
                       mov word ptr es:[bx],ax
                       mov ax,word ptr cs:[@cb+3]
                       mov word ptr es:[bx+2],ax
                       mov ax,word ptr cs:[@cb+5]
                       mov word ptr es:[bx+4],ax
                       mov ax,word ptr cs:[@cb+7]
                       mov word ptr es:[bx+6],ax
                       pop es
                       pop bx
                       xor ax,ax
                   @er:
                  end;
{
*********************************************************
 ПОЛУЧАЕМ DEVICE STATUS
  num - номер CD драйва ( от 1 ) из массива
*********************************************************
}

          function cdrom_device_status(num:byte;var stat:longint):byte;assembler;
                       asm
                       jmp @l0
                   @cb:db 6
                       dd 0
                   @l0:mov al,num
                       mov ah,0
                       push ax
                       mov ax,cs
                       push ax
                       mov ax,offset cs:[@cb]
                       push ax
                       mov ax,5
                       push ax
                       mov ax,3
                       push ax
                       call cdrom_ioctl
                       or ax,ax
                       jnz @er
                       push bx
                       push es
                       les bx,stat
                       mov ax,word ptr cs:[@cb+1]
                       mov word ptr es:[bx],ax
                       mov ax,word ptr cs:[@cb+3]
                       mov word ptr es:[bx+2],ax
                       pop es
                       pop bx
                       xor ax,ax
                   @er:
                       end;

{
*********************************************************
 ПОЛУЧАЕМ РАЗМЕР СЕКТОРА
  num - номер CD драйва ( от 1 ) из массива
  adr - режим адресации
*********************************************************
}

          function cdrom_sector_size(num,adr:byte;var size:word):byte;assembler;
                       asm
                       jmp @l0
                   @cb:db 7
                       db 0
                       dw 0
                   @l0:mov al,adr
                       mov byte ptr cs:[@cb+1],al
                       mov al,num
                       mov ah,0
                       push ax
                       mov ax,cs
                       push ax
                       mov ax,offset cs:[@cb]
                       push ax
                       mov ax,4
                       push ax
                       mov ax,3
                       push ax
                       call cdrom_ioctl
                       or ax,ax
                       jnz @er
                       push bx
                       push es
                       les bx,size
                       mov ax,word ptr cs:[@cb+2]
                       mov word ptr es:[bx],ax
                       pop es
                       pop bx
                       xor ax,ax
                   @er:
                       end;
{
*********************************************************
 ПОЛУЧАЕМ РАЗМЕР ДИСКА
  num - номер CD драйва ( от 1 ) из массива
*********************************************************
}

          function cdrom_volume_size(num:byte;var size:longint):byte;assembler;
                   asm
                       jmp @l0
                   @cb:db 8
                       dd 0
                   @l0:mov al,num
                       mov ah,0
                       push ax
                       mov ax,cs
                       push ax
                       mov ax,offset cs:[@cb]
                       push ax
                       mov ax,5
                       push ax
                       mov ax,3
                       push ax
                       call cdrom_ioctl
                       or ax,ax
                       jnz @er
                       push bx
                       push es
                       les bx,size
                       mov ax,word ptr cs:[@cb+1]
                       mov word ptr es:[bx],ax
                       mov ax,word ptr cs:[@cb+3]
                       mov word ptr es:[bx+2],ax
                       pop es
                       pop bx
                       xor ax,ax
                   @er:
                       end;
{
*********************************************************
 ПРОВЕРКА СМЕНЫ НОСИТЕЛЯ
  num - номер CD драйва ( от 1 ) из массива
  m = 1  - не изменился
  m = 0  - не известно
  m = FF - изменился
*********************************************************
}

            function cdrom_media_changed(num:byte;var m:byte):byte;assembler;
                     asm
                       jmp @l0
                   @cb:db 9
                       db 0
                   @l0:mov al,num
                       mov ah,0
                       push ax
                       mov ax,cs
                       push ax
                       mov ax,offset cs:[@cb]
                       push ax
                       mov ax,2
                       push ax
                       mov ax,3
                       push ax
                       call cdrom_ioctl
                       or ax,ax
                       jnz @er
                       push bx
                       push es
                       les bx,m
                       mov al,byte ptr cs:[@cb+1]
                       mov byte ptr es:[bx],al
                       pop es
                       pop bx
                       xor ax,ax
                   @er:
                     end;
{
*********************************************************
 ИНФОРМАЦИЯ ОБ АУДИОДИСКЕ
  num - номер CD драйва ( от 1 ) из массива
*********************************************************
}
            function cdrom_auddisk_info(num:byte;var a:aud_disk):byte;assembler;
                     asm
                       jmp @l0
                   @cb:db 10
                       db 0
                       db 0
                       dd 0
                   @l0:mov al,num
                       mov ah,0
                       push ax
                       mov ax,cs
                       push ax
                       mov ax,offset cs:[@cb]
                       push ax
                       mov ax,7
                       push ax
                       mov ax,3
                       push ax
                       call cdrom_ioctl
                       or ax,ax
                       jnz @er
                       push bx
                       push es
                       les bx,a
                       mov ax,word ptr cs:[@cb+1]
                       mov word  ptr es:[bx],ax
                       mov ax,word ptr cs:[@cb+3]
                       mov word  ptr es:[bx+2],ax
                       mov ax,word ptr cs:[@cb+5]
                       mov word  ptr es:[bx+4],ax
                       pop es
                       pop bx
                       xor ax,ax
                   @er:
                     end;
{
*********************************************************
 ИНФОРМАЦИЯ ОБ АУДИОДОРОЖКЕ
  num - номер CD драйва ( от 1 ) из массива
  n   - номер дорожки
*********************************************************
}
          function cdrom_audtrack_info(num,n:byte;var a:aud_track):byte;assembler;
                   asm
                       jmp @l0
                   @cb:db 11
                       db 0
                       dd 0
                       db 0
                   @l0:mov al,n
                       mov byte ptr cs:[@cb+1],al
                       mov al,num
                       mov ah,0
                       push ax
                       mov ax,cs
                       push ax
                       mov ax,offset cs:[@cb]
                       push ax
                       mov ax,7
                       push ax
                       mov ax,3
                       push ax
                       call cdrom_ioctl
                       or ax,ax
                       jnz @er
                       push bx
                       push es
                       les bx,a
                       mov ax,word ptr cs:[@cb+2]
                       mov word  ptr es:[bx],ax
                       mov ax,word ptr cs:[@cb+4]
                       mov word  ptr es:[bx+2],ax
                       mov al,byte ptr cs:[@cb+5]
                       mov byte ptr es:[bx+4],al
                       pop es
                       pop bx
                       xor ax,ax
                   @er:
                   end;
{
*********************************************************
 ИНФОРМАЦИЯ О ТЕКУЩЕМ СОСТОЯНИИ ПРОИГРЫВАНИЯ АУДИОДИСКА
  num - номер CD драйва ( от 1 ) из массива
*********************************************************
}
        function cdrom_audQchnl_info(num:byte;var a:aud_Qchnl):byte;assembler;
                         asm
                       jmp @l0
                   @cb:db 12
                       db 0 { режим адресации  }
                       db 0 { номер дорожки    }
                       db 0 { point или индекс }

                       db 0
                       db 0
                       db 0
                       db 0

                       db 0
                       db 0
                       db 0

                   @l0:mov al,num
                       mov ah,0
                       push ax
                       mov ax,cs
                       push ax
                       mov ax,offset cs:[@cb]
                       push ax
                       mov ax,11
                       push ax
                       mov ax,3
                       push ax
                       call cdrom_ioctl
                       or ax,ax
                       jnz @er
                       push bx
                       push es
                       les bx,a
                       mov ax,word ptr cs:[@cb+1]
                       mov word  ptr es:[bx],ax
                       mov ax,word ptr cs:[@cb+3]
                       mov word  ptr es:[bx+2],ax
                       mov ax,word ptr cs:[@cb+5]
                       mov word ptr es:[bx+4],ax
                       mov ax,word ptr cs:[@cb+7]
                       mov word ptr es:[bx+6],ax
                       mov ax,word ptr cs:[@cb+9]
                       mov word ptr es:[bx+8],ax
                       pop es
                       pop bx
                       xor ax,ax
                   @er:
                   end;
{
*********************************************************
 ПОЛУЧЕНИЕ ИНФОРМАЦИИ О КАЖДОМ ИЗ ПОДКАНАЛОВ ( 1 канал - 96 байт )
  num - номер CD драйва ( от 1 ) из массива
  start - red book нач. адрес
  n     - число секторов
  adr   - адрес буфера
*********************************************************
}

         function cdrom_audSubchnl_info(num:byte;start,n:longint;adr:pointer):byte;assembler;
                  asm
                       jmp @l0
                   @cb:db 13
                       dd 0 {  RED BOOK нач. адрес }
                       dd 0 {  адрес буфера        }
                       dd 0 {  число секторов      }

                   @l0:mov ax,word ptr [start]
                       mov word ptr cs:[@cb+1],ax
                       mov ax,word ptr [start+2]
                       mov word ptr cs:[@cb+3],ax

                       mov ax,word ptr [adr]
                       mov word ptr cs:[@cb+5],ax
                       mov ax,word ptr [adr+2]
                       mov word ptr cs:[@cb+7],ax

                       mov ax,word ptr [n]
                       mov word ptr cs:[@cb+9],ax
                       mov ax,word ptr [n+2]
                       mov word ptr cs:[@cb+11],ax


                       mov al,num
                       mov ah,0
                       push ax
                       mov ax,cs
                       push ax
                       mov ax,offset cs:[@cb]
                       push ax
                       mov ax,13
                       push ax
                       mov ax,3
                       push ax
                       call cdrom_ioctl
                  end;
{
*********************************************************
 ПОЛУЧЕНИЕ UPC КОДА ДИСКА
*********************************************************
}
         function cdrom_upccode_read(num:byte;var code:upc):byte;assembler;
                  asm
                       jmp @l0
                   @cb:db 14
                       db 2 { режим адресации  }

                       db 0 { код  }
                       db 0
                       db 0
                       db 0
                       db 0
                       db 0
                       db 0

                       db 0
                       db 0

                   @l0:mov al,num
                       mov ah,0
                       push ax
                       mov ax,cs
                       push ax
                       mov ax,offset cs:[@cb]
                       push ax
                       mov ax,11
                       push ax
                       mov ax,3
                       push ax
                       call cdrom_ioctl
                       or ax,ax
                       jnz @er
                       push bx
                       push es
                       push si
                       push cx
                       les bx,code
                       mov al,byte ptr cs:[@cb+1]
                       mov byte ptr es:[bx],al
                       inc bx
                       { es:bx - начало массива кода }
                       mov si,offset cs:[@cb+2]
                       mov ax,cs
                       push ds
                       mov ds,ax
                       mov cx,6
                       cld
                   @l1:lodsb
                       mov ah,al
                       and ax,0ff0h
                       mov byte ptr es:[bx],ah
                       shr al,1
                       shr al,1
                       shr al,1
                       shr al,1
                       inc bx
                       mov byte ptr es:[bx],al
                       inc bx
                       loop @l1
                       lodsb
                       and al,0fh
                       mov byte ptr es:[bx],al
                       inc bx
                       pop ds
                       mov ax,word ptr cs:[@cb+9]
                       mov word ptr es:[bx],ax
                       pop cx
                       pop si
                       pop es
                       pop bx
                       xor ax,ax
                   @er:
                  end;
{
*********************************************************
 ПОЛУЧЕНИЕ СТАТУСА АУДИО ДИСКА
*********************************************************
}
          function cdrom_AudStat_read(num:byte;var s:Aud_stat):byte;assembler;
                   asm
                       jmp @l0
                   @cb:db 15
                       dw 0
                       dd 0
                       dd 0

                   @l0:
                       mov al,num
                       mov ah,0
                       push ax
                       mov ax,cs
                       push ax
                       mov ax,offset cs:[@cb]
                       push ax
                       mov ax,11
                       push ax
                       mov ax,3
                       push ax
                       call cdrom_ioctl
                       or ax,ax
                       jnz @er
                       push bx
                       push es
                       les bx,s
                       mov ax,word ptr cs:[@cb+1]
                       mov word ptr es:[bx],ax
                       mov ax,word ptr cs:[@cb+3]
                       mov word ptr es:[bx+2],ax
                       mov ax,word ptr cs:[@cb+5]
                       mov word ptr es:[bx+4],ax
                       mov ax,word ptr cs:[@cb+7]
                       mov word ptr es:[bx+6],ax
                       mov ax,word ptr cs:[@cb+9]
                       mov word ptr es:[bx+8],ax
                       xor ax,ax
                   @er:
                  end;
{
*********************************************************
 ВЫБРОС ДИСКА
*********************************************************
}
      function cdrom_open_tray(num:byte):byte;assembler;
               asm
                    jmp @l0
                   @cb:db 0
                   @l0:mov al,num
                       mov ah,0
                       push ax
                       mov ax,cs
                       push ax
                       mov ax,offset cs:[@cb]
                       push ax
                       mov ax,1
                       push ax
                       mov ax,12
                       push ax
                       call cdrom_ioctl
                  end;
{
*********************************************************
 ЗАКРЫВАНИЕ ДВЕРИ
*********************************************************
}
      function cdrom_close_tray(num:byte):byte;assembler;
               asm
                    jmp @l0
                   @cb:db 5
                   @l0:mov al,num
                       mov ah,0
                       push ax
                       mov ax,cs
                       push ax
                       mov ax,offset cs:[@cb]
                       push ax
                       mov ax,1
                       push ax
                       mov ax,12
                       push ax
                       call cdrom_ioctl
                  end;

{
*********************************************************
 ЗАКРЫВАНИЕ МЕХАНИЗМА
*********************************************************
}
      function cdrom_lock_door(num:byte):byte;assembler;
               asm
                  jmp @l0
                   @cb:db 1
                       db 1
                   @l0:mov al,num
                       mov ah,0
                       push ax
                       mov ax,cs
                       push ax
                       mov ax,offset cs:[@cb]
                       push ax
                       mov ax,2
                       push ax
                       mov ax,12
                       push ax
                       call cdrom_ioctl
               end;
{
*********************************************************
 ОТКРЫВАНИЕ МЕХАНИЗМА
*********************************************************
}
      function cdrom_unlock_door(num:byte):byte;assembler;
               asm
                       jmp @l0
                   @cb:db 1
                       db 0
                   @l0:mov al,num
                       mov ah,0
                       push ax
                       mov ax,cs
                       push ax
                       mov ax,offset cs:[@cb]
                       push ax
                       mov ax,2
                       push ax
                       mov ax,12
                       push ax
                       call cdrom_ioctl
               end;
{
*********************************************************
 ИНИЦИАЛИЗАЦИЯ CDROMа
*********************************************************
}

       function cdrom_reset(num:byte):byte;assembler;
                asm
                jmp @l0
                   @cb:db 2
                   @l0:mov al,num
                       mov ah,0
                       push ax
                       mov ax,cs
                       push ax
                       mov ax,offset cs:[@cb]
                       push ax
                       mov ax,1
                       push ax
                       mov ax,12
                       push ax
                       call cdrom_ioctl
               end;
{
*********************************************************
 УПРАВЛЕНИЕ АУДИО-КАНАЛАМИ
*********************************************************
}
       function cdrom_AudChnl_ctrl(num:byte;var a:aud_chnl):byte;assembler;
                       asm
                       jmp @l0
                   @cb:db 3
                       dd 0
                       dd 0
                   @l0:push bx
                       push es
                       les bx,a
                       mov ax,word ptr es:[bx]
                       mov word ptr cs:[@cb+1],ax
                       mov ax,word ptr es:[bx+2]
                       mov word ptr cs:[@cb+3],ax
                       mov ax,word ptr es:[bx+4]
                       mov word ptr cs:[@cb+5],ax
                       mov ax,word ptr es:[bx+6]
                       mov word ptr cs:[@cb+7],ax
                       pop es
                       pop bx
                       mov al,num
                       mov ah,0
                       push ax
                       mov ax,cs
                       push ax
                       mov ax,offset cs:[@cb]
                       push ax
                       mov ax,9
                       push ax
                       mov ax,12
                       push ax
                       call cdrom_ioctl
                end;
{
*********************************************************
 Считывание данных ( пока не выполнится )
 num - номер CD ROMа
 com - код команды
*********************************************************
}
       function cdrom_readlong(num:byte;var adr:read):byte;assembler;
                       asm
                       push bx
                       push es
                       push cx
                       mov al,num
                       mov ah,cd_num
                       cmp al,ah
                       ja @e1
                       mov al,hdr_present
                       or al,al
                       jz @e2
                       mov ax,word ptr hdr
                       mov es,ax
                       xor bx,bx
                       { es:bx - память заголовка }
                       mov byte ptr es:[bx],27
                       mov byte ptr es:[bx+1],0
                       mov byte ptr es:[bx+2],128
                       add bx,13
                       { es:bx - адрес после reqhdr в headerе }
                       cld
                       push ds
                       lds si,adr
                       mov cx,7
                   @l1:lodsw
                       mov word ptr es:[bx],ax
                       inc bx
                       inc bx
                       loop @l1
                       pop ds
                       mov al,num
                       mov ah,0
                       push ax
                       call request
                       test ah,80h
                       jnz @e3
                       mov ax,0
                       jmp @er
                   @e3:add al,83h
                       jmp @er
                   @e2:mov ax,82h
                       jmp @er
                   @e1:mov ax,81h
                       jmp @er
                   @er:mov ah,0
                       pop cx
                       pop es
                       pop bx
                       end;
{
*********************************************************
 Считывание данных ( возврат сразу )
 num - номер CD ROMа
 com - код команды
*********************************************************
}
       function cdrom_readlong_prefetch(num:byte;var adr:read):byte;assembler;
                       asm
                       push bx
                       push es
                       push cx
                       mov al,num
                       mov ah,cd_num
                       cmp al,ah
                       ja @e1
                       mov al,hdr_present
                       or al,al
                       jz @e2
                       mov ax,word ptr hdr
                       mov es,ax
                       xor bx,bx
                       { es:bx - память заголовка }
                       mov byte ptr es:[bx],27
                       mov byte ptr es:[bx+1],0
                       mov byte ptr es:[bx+2],130
                       add bx,13
                       { es:bx - адрес после reqhdr в headerе }
                       cld
                       push ds
                       lds si,adr
                       mov cx,7
                   @l1:lodsw
                       mov word ptr es:[bx],ax
                       inc bx
                       inc bx
                       loop @l1
                       pop ds
                       mov al,num
                       mov ah,0
                       push ax
                       call request
                       test ah,80h
                       jz @er
                   @e3:add al,83h
                       jmp @er
                   @e2:mov al,82h
                       jmp @er
                   @e1:mov al,81h
                       jmp @er
                   @er:mov ah,0
                       pop cx
                       pop es
                       pop bx
                       end;
{
*********************************************************
 Позиционирование головки
 num - номер CD ROMа
*********************************************************
}
      function cdrom_seek(num,adr:byte;pos:longint):byte;assembler;
                       asm
                       push bx
                       push es
                       push cx
                       mov al,num
                       mov ah,cd_num
                       cmp al,ah
                       ja @e1
                       mov al,hdr_present
                       or al,al
                       jz @e2
                       mov ax,word ptr hdr
                       mov es,ax
                       xor bx,bx
                       { es:bx - память заголовка }
                       mov byte ptr es:[bx],24
                       mov byte ptr es:[bx+1],0
                       mov byte ptr es:[bx+2],131
                       mov al,adr
                       mov ah,0
                       mov byte ptr es:[bx+14],al
                       mov ax,word ptr [pos]
                       mov word ptr es:[bx+21],ax
                       mov ax,word ptr [pos+2]
                       mov word ptr es:[bx+23],ax

                       mov al,num
                       mov ah,0
                       push ax
                       call request
                       test ah,80h
                       jz @er
                   @e3:add al,83h
                       jmp @er
                   @e2:mov al,82h
                       jmp @er
                   @e1:mov al,81h
                       jmp @er
                   @er:mov ah,0
                       pop cx
                       pop es
                       pop bx
                       end;
{
*********************************************************
 PLAY AUDIO
 num - номер CD ROMа
 adr - режим адресации
 start - номер первого сектора
 n - число секторов
*********************************************************
}
      function cdrom_audplay(num,adr:byte;start,n:longint):byte;assembler;
               asm
                       push bx
                       push es
                       push cx
                       mov al,num
                       mov ah,cd_num
                       cmp al,ah
                       ja @e1
                       mov al,hdr_present
                       or al,al
                       jz @e2
                       mov ax,word ptr hdr
                       mov es,ax
                       xor bx,bx
                       { es:bx - память заголовка }
                       mov byte ptr es:[bx],22
                       mov byte ptr es:[bx+1],0
                       mov byte ptr es:[bx+2],132
                       mov al,adr
                       mov byte ptr es:[bx+13],al

                       mov ax,word ptr [start]
                       mov word ptr es:[bx+14],ax
                       mov ax,word ptr [start+2]
                       mov word ptr es:[bx+16],ax

                       mov ax,word ptr [n]
                       mov word ptr es:[bx+18],ax
                       mov ax,word ptr [n+2]
                       mov word ptr es:[bx+20],ax


                       mov al,num
                       mov ah,0
                       push ax
                       call request
                       test ah,80h
                       jz @er
                   @e3:add al,83h
                       jmp @er
                   @e2:mov al,82h
                       jmp @er
                   @e1:mov al,81h
                       jmp @er
                   @er:mov ah,0
                       pop cx
                       pop es
                       pop bx
                       end;
{
*********************************************************
 ПОСЫЛКА ОДНОЙ КОМАНДЫ CDROMу
 num - номер CD ROMа
 com - код команды
*********************************************************
}

               function cdrom_one(num,com:byte):byte;assembler;
                  asm
                       push bx
                       push es
                       push cx
                       mov al,num
                       mov ah,cd_num
                       cmp al,ah
                       ja @e1
                       mov al,hdr_present
                       or al,al
                       jz @e2
                       mov ax,word ptr hdr
                       mov es,ax
                       xor bx,bx
                       { es:bx - память заголовка }
                       mov byte ptr es:[bx],13
                       mov byte ptr es:[bx+1],0
                       mov al,byte ptr com
                       mov byte ptr es:[bx+2],al


                       mov al,num
                       mov ah,0
                       push ax
                       call request
                       test ah,80h
                       jz @er
                   @e3:add al,83h
                       jmp @er
                   @e2:mov al,82h
                       jmp @er
                   @e1:mov al,81h
                       jmp @er
                   @er:mov ah,0
                       pop cx
                       pop es
                       pop bx
                       end;

{
*********************************************************
 STOP AUDIO
 num - номер CD ROMа
*********************************************************
}
         function cdrom_audstop(num:byte):byte;assembler;
                  asm


                       mov al,num
                       mov ah,0
                       push ax
                       mov al,133
                       mov ah,0
                       push ax
                       call cdrom_one
                       end;
{
*********************************************************
 RESUME AUDIO
 num - номер CD ROMа
*********************************************************
}
         function cdrom_audresume(num:byte):byte;assembler;
                       asm
                       mov al,num
                       mov ah,0
                       push ax
                       mov al,136
                       mov ah,0
                       push ax
                       call cdrom_one
                       end;
{
*********************************************************
 INPUT FLUSH
 num - номер CD ROMа
*********************************************************
}
          function cdrom_inputflush(num:byte):byte;assembler;
                      asm
                       mov al,num
                       mov ah,0
                       push ax
                       mov al,7
                       mov ah,0
                       push ax
                       call cdrom_one
                       end;

{
*********************************************************
 CDROM DEVICE OPEN
 num - номер CD ROMа
*********************************************************
}
         function cdrom_device_open(num:byte):byte;assembler;
                       asm
                       mov al,num
                       mov ah,0
                       push ax
                       mov al,13
                       mov ah,0
                       push ax
                       call cdrom_one
                  end;
{
*********************************************************
 CDROM DEVICE CLOSE
 num - номер CD ROMа
*********************************************************
}
         function cdrom_device_close(num:byte):byte;assembler;
                       asm
                       mov al,num
                       mov ah,0
                       push ax
                       mov al,14
                       mov ah,0
                       push ax
                       call cdrom_one
                  end;
{
*********************************************************
 ПРЕОБРАЗОВАНИЕ АДРЕСА ИЗ ФОРМАТА RED BOOK в ФОРМАТ SECTORs
 без вычитания 150
*********************************************************
}
        procedure cdrom_redbook_sector(rb:longint;var sect:longint);assembler;
                  asm
                  push ax
                  push bx
                  push cx
                  push dx
                  push es
                  mov ax,word ptr rb
                  { al - frame,ah - second }
                  mov bl,al
                  mov bh,0
                  mov al,ah
                  mov ah,75
                  mul ah
                  { ax - second*75 }
                  mov cx,ax
                  { bx - frames     }
                  { cx - seconds*75 }
                  mov ax,word ptr [rb+2]
                  mov ah,0
                  mov dx,4500
                  mul dx
                  { dx:ax - сектор }
                  add ax,cx
                  adc dx,0
                  add ax,bx
                  adc dx,0
                  { dx:ax - сектор }
                  les bx,sect
                  mov word ptr es:[bx],ax
                  mov word ptr es:[bx+2],dx
                  pop es
                  pop dx
                  pop cx
                  pop bx
                  pop ax
                  end;
{
*********************************************************
 ПРЕОБРАЗОВАНИЕ АДРЕСА ИЗ SECTOR в ФОРМАТ RED BOOK
 без вычитания 150
*********************************************************
}
        procedure cdrom_sector_redbook(sect:longint;var rb:longint);
              var m,s,frm:longint;
                  begin
                  m:=sect div 4500;
                  frm:=sect-(m*4500);
                  s:=frm div 75;
                  frm:=frm-(s*75);
                  rb:=m*65536+s*256+frm;
                  end;


{
*********************************************************
 CDROM SONG INFO
 num - номер CD ROMа
 adr - адрес памяти массива структур типа SONG
 k   - количество дорожек на диске
*********************************************************
}
      function cdrom_song_info(num:byte;adr:pointer;var k:byte):byte;
           var d:aud_disk;
               t,e:aud_track;
               track:byte;
               size,tsize,sl1,sl2:longint;
               s,f:byte;   { f       - номер дорожки звука ( от 0 ) }
               begin       { track   - номер дорожки на диске       }
               k:=0;       { t.start - начало в RED BOOK ADR        }
                           { tsize   - размер дорожки               }
               s:=cdrom_AudDisk_info(num,d);
               if s=0 then
                begin
                 s:=cdrom_volume_size(num,size);
                 if s=0 then
                    begin
                 track:=d.low;f:=0;
                 while ((cdrom_audtrack_info(num,track,t)=0) and (track<=d.high)) do
                              begin
                              if (t.info and $40)=0 then
                                    begin
                                    if track=d.high then begin
                                                         cdrom_redbook_sector(t.start,sl1);
                                                         tsize:=size-sl1;
                                                         end
                                    else
                                                         begin
                                                         cdrom_audtrack_info(num,track+1,e);
                                                         cdrom_redbook_sector(t.start,sl1);
                                                         cdrom_redbook_sector(e.start,sl2);
                                                         tsize:=sl2-sl1;
                                                         end;
                                    { преобразуем tsize в RED BOOK }
                                    cdrom_sector_redbook(tsize,tsize);
                                    { все данные получены }
                                    { f       - номер дорожки звука ( от 0 ) }
                                    { track   - номер дорожки на диске       }
                                    { t.start - начало в RED BOOK ADR        }
                                    { tsize   - размер дорожки               }
                                    asm
                                    push es
                                    push dx
                                    push bx
                                    push ax
                                    mov ax,word ptr [adr+2]
                                    mov es,ax
                                    mov bx,word ptr [adr]

                                    mov al,f
                                    mov ah,9
                                    mul ah
                                    add bx,ax
                                    jnc @l1
                                    mov ax,es
                                    add ax,1000h
                                    mov es,ax
                               @l1: { es:bx - запись }
                                    mov al,track
                                    mov byte ptr es:[bx],al
                                    mov ax,word ptr [t.start]
                                    mov word ptr es:[bx+1],ax
                                    mov ax,word ptr [t.start+2]
                                    mov word ptr es:[bx+3],ax

                                    mov ax,word ptr [tsize]
                                    mov word ptr es:[bx+5],ax
                                    mov ax,word ptr [tsize+2]
                                    mov word ptr es:[bx+7],ax

                                    pop ax
                                    pop bx
                                    pop dx
                                    pop es
                                    end;
                                    inc(k);
                                    f:=f+1;
                                    end;
                              track:=track+1;
                              end;
                   end;
                end;
               cdrom_song_info:=s;
               end;
              begin
              hdr_present:=false;
              cdrom_check;make_hdr(16);
              end.


