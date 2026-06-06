;the entire code of the best game in the whole world, written fully in x64 assembly.

option casemap:none

include windows.inc

includelib kernel32.lib
includelib user32.lib
includelib gdi32.lib

;badass functions

WinProc PROTO :QWORD,:QWORD,:QWORD,:QWORD
UIntToDec PROTO :QWORD,:QWORD
InitGraphics PROTO :QWORD,:QWORD
ClearBackBuffer PROTO
DrawSprite PROTO
RenderFrame PROTO :QWORD,:QWORD
DrawTileLayer PROTO
DrawBackSky PROTO
DrawBackClouds PROTO
DrawBackWater PROTO
DrawForeground PROTO
DrawBilly PROTO
PresentBackBuffer PROTO :QWORD,:QWORD,:QWORD
GetTickCount64 PROTO
Collision PROTO :QWORD,:QWORD

;sprites,palettes and bytes

.data

ClassName db "GameBooter",0
WindowName db "The Game",0

HelloText db "Hello Mom & Dad!",0
CounterLabel db "Counter: ",0
CounterBuffer db "0",31 dup(0)

Err1 db "RegisterClassEx FAILED",0
Err2 db "CreateWindowEx FAILED",0
ErrT db "ERROR",0

Counter dq 0
SlowCounter dq 0
CounterLen dq 1

FPSLabel db "FPS: ",0
FPSBuffer db "0",31 dup(0)

FrameCounter dq 0
FPSValue dq 0
FPSLen dq 1
LastFPSTick dq 0
CurrentFPSTick dq 0

PlayerX dq 200
PlayerY dq 160

KeyLeft dq 0
KeyRight dq 0
KeyUp dq 0
KeyDown dq 0

MoveCounter dq 0

BillyScale dq 1

MapWidth dq 32
MapHeight dq 16

BeachTileSet LABEL BYTE
INCBIN "Tileset\TileSetBeach.bin"

BeachPalette LABEL DWORD
INCBIN "Palette\BeachPalette.pal"

MapBackSky LABEL BYTE
INCBIN "Maps\Beach\Back_Sky.bin"

MapBackClouds LABEL BYTE
INCBIN "Maps\Beach\Back_Clouds.bin"

MapBackWater LABEL BYTE
INCBIN "Maps\Beach\Back_Water.bin"

MapForeground LABEL BYTE
INCBIN "Maps\Beach\Foreground.bin"

BillyPixels LABEL BYTE
INCBIN "Objects\Billy\Billy.bin"

BillyPalette LABEL DWORD
INCBIN "Palette\Billy.pal"


BillyWidth dq 30
BillyHeight dq 40
BillyFrameSize dq 1200
BillyCurrentFrame dq 0

.data?

align 8

hInstance dq ?
hWnd dq ?

wc WNDCLASSEX <>
msg MSG <>
ps PAINTSTRUCT <>
ClientRect RECT <>

hdc dq ?

BackBufferWidth dq ?
BackBufferHeight dq ?
BackBufferMemory dq ?
BackBufferDC dq ?
BackBufferBitmap dq ?

BitmapInfo BITMAPINFO <>

ScreenWidth dq ?
ScreenHeight dq ?

;functions of the game.

.code

start PROC

    invoke GetModuleHandle,NULL
    mov hInstance,rax

    mov wc.cbSize,SIZEOF WNDCLASSEX
    mov wc.style,CS_HREDRAW or CS_VREDRAW

    lea rax,WinProc
    mov wc.lpfnWndProc,rax

    mov wc.cbClsExtra,0
    mov wc.cbWndExtra,0

    mov rax,hInstance
    mov wc.hInstance,rax

    mov wc.hIcon,NULL

    invoke LoadCursor,NULL,IDC_ARROW
    mov wc.hCursor,rax

    invoke GetStockObject,BLACK_BRUSH
    mov wc.hbrBackground,rax

    mov wc.lpszMenuName,NULL

    lea rax,ClassName
    mov wc.lpszClassName,rax

    mov wc.hIconSm,NULL

    invoke RegisterClassEx,ADDR wc

    test rax,rax
    jnz ClassOK

    invoke MessageBox,NULL,ADDR Err1,ADDR ErrT,MB_OK
    invoke ExitProcess,0

ClassOK:

	invoke GetSystemMetrics,SM_CXSCREEN
	mov ScreenWidth,rax

	invoke GetSystemMetrics,SM_CYSCREEN
	mov ScreenHeight,rax

    invoke CreateWindowEx,\
        0,\
        ADDR ClassName,\
        ADDR WindowName,\
        WS_POPUP,\
        0,\
        0,\
		dword ptr [ScreenWidth],\
		dword ptr [ScreenHeight],\
        NULL,\
        NULL,\
        hInstance,\
        NULL

    mov hWnd,rax

    test rax,rax
    jnz WindowOK

    invoke MessageBox,NULL,ADDR Err2,ADDR ErrT,MB_OK
    invoke ExitProcess,0

WindowOK:

    mov rcx,320
    mov rdx,240
    sub rsp,32
    call InitGraphics
    add rsp,32

    invoke ShowWindow,hWnd,SW_SHOW
    invoke UpdateWindow,hWnd

    invoke GetTickCount64
    mov qword ptr [LastFPSTick],rax

MainLoop:

    invoke PeekMessage,\
        ADDR msg,\
        NULL,\
        0,\
        0,\
        PM_REMOVE

    test eax,eax
    jz NoMessage

    cmp msg.message,WM_QUIT
    je ExitProgram

    invoke TranslateMessage,ADDR msg
    invoke DispatchMessage,ADDR msg

    jmp MainLoop

NoMessage:

    inc qword ptr [FrameCounter]

    inc qword ptr [MoveCounter]

    cmp qword ptr [MoveCounter],5
    jl SkipMovement

    mov qword ptr [MoveCounter],0

    cmp qword ptr [KeyLeft],1
	jne MoveRightCheck

	mov rcx,qword ptr [PlayerX]
	sub rcx,1
	mov rdx,qword ptr [PlayerY]
	sub rsp,32
	call Collision
	add rsp,32

	cmp rax,0
	jne MoveRightCheck

	sub qword ptr [PlayerX],1

MoveRightCheck:

    cmp qword ptr [KeyRight],1
    jne MoveUpCheck

    mov rcx,qword ptr [PlayerX]
    add rcx,1
    mov rdx,qword ptr [PlayerY]
    sub rsp,32
    call Collision
    add rsp,32

    cmp rax,0
    jne MoveUpCheck

    add qword ptr [PlayerX],1

MoveUpCheck:

    cmp qword ptr [KeyUp],1
    jne MoveDownCheck

    mov rcx,qword ptr [PlayerX]
    mov rdx,qword ptr [PlayerY]
    sub rdx,1
    sub rsp,32
    call Collision
    add rsp,32

    cmp rax,0
    jne MoveDownCheck

    sub qword ptr [PlayerY],1

MoveDownCheck:

    cmp qword ptr [KeyDown],1
    jne MoveDone

    mov rcx,qword ptr [PlayerX]
    mov rdx,qword ptr [PlayerY]
    add rdx,1
    sub rsp,32
    call Collision
    add rsp,32

    cmp rax,0
    jne MoveDone

    add qword ptr [PlayerY],1

MoveDone:

    cmp qword ptr [PlayerX],0
    jge CheckRightBorder
    mov qword ptr [PlayerX],0

CheckRightBorder:

    mov rax,288

    cmp qword ptr [PlayerX],rax
    jle CheckTopBorder
    mov qword ptr [PlayerX],rax

CheckTopBorder:

    cmp qword ptr [PlayerY],0
    jge CheckBottomBorder
    mov qword ptr [PlayerY],0

CheckBottomBorder:

    mov rax,208

    cmp qword ptr [PlayerY],rax
    jle BorderDone
    mov qword ptr [PlayerY],rax

BorderDone:

SkipMovement:

    invoke GetTickCount64
    mov qword ptr [CurrentFPSTick],rax

    sub rax,qword ptr [LastFPSTick]
    cmp rax,1000
    jb SkipFPSUpdate

    mov rax,qword ptr [CurrentFPSTick]
    mov qword ptr [LastFPSTick],rax

    mov rax,qword ptr [FrameCounter]
    mov qword ptr [FPSValue],rax
    mov qword ptr [FrameCounter],0

    mov rcx,qword ptr [FPSValue]
    lea rdx,FPSBuffer
    sub rsp,32
    call UIntToDec
    add rsp,32

    mov qword ptr [FPSLen],rax

SkipFPSUpdate:

    inc qword ptr [SlowCounter]

    cmp qword ptr [SlowCounter],50000
    jl SkipCounterUpdate

    mov qword ptr [SlowCounter],0

    inc qword ptr [Counter]

    mov rcx,qword ptr [Counter]
    lea rdx,CounterBuffer
    sub rsp,32
    call UIntToDec
    add rsp,32

    mov qword ptr [CounterLen],rax

SkipCounterUpdate:

    invoke InvalidateRect,\
        hWnd,\
        NULL,\
        FALSE

    jmp MainLoop

ExitProgram:

    invoke ExitProcess,0

start ENDP

WinProc PROC hwnd:QWORD,uMsg:QWORD,wParam:QWORD,lParam:QWORD

    cmp edx,WM_DESTROY
    je wmDestroy

    cmp edx,WM_PAINT
    je wmPaint

    cmp edx,WM_ERASEBKGND
    je wmEraseBkgnd

    cmp edx,WM_KEYDOWN
    je wmKeyDown

    cmp edx,WM_KEYUP
    je wmKeyUp

DefaultMessage:

    sub rsp,32
    call DefWindowProcA
    add rsp,32

    ret

wmPaint:

    invoke GetClientRect,hwnd,ADDR ClientRect

    mov rcx,hwnd
    lea rdx,ps
    sub rsp,32
    call BeginPaint
    add rsp,32

    mov hdc,rax

    mov rcx,qword ptr [PlayerX]
    mov rdx,qword ptr [PlayerY]
    sub rsp,32
    call RenderFrame
    add rsp,32

    mov rcx,hdc
    mov edx,ClientRect.right
    mov r8d,ClientRect.bottom
    sub rsp,32
    call PresentBackBuffer
    add rsp,32

    mov rcx,hwnd
    lea rdx,ps
    sub rsp,32
    call EndPaint
    add rsp,32

    xor eax,eax
    ret

wmEraseBkgnd:

    mov eax,1
    ret

wmKeyDown:

    cmp r8d,VK_LEFT
    jne KeyDownRight
    mov qword ptr [KeyLeft],1
    jmp KeyDownDone

KeyDownRight:

    cmp r8d,VK_RIGHT
    jne KeyDownUp
    mov qword ptr [KeyRight],1
    jmp KeyDownDone

KeyDownUp:

    cmp r8d,VK_UP
    jne KeyDownDown
    mov qword ptr [KeyUp],1
    jmp KeyDownDone

KeyDownDown:

    cmp r8d,VK_DOWN
    jne KeyDownDone
    mov qword ptr [KeyDown],1

KeyDownDone:

    xor eax,eax
    ret

wmKeyUp:

    cmp r8d,VK_LEFT
    jne KeyUpRight
    mov qword ptr [KeyLeft],0
    jmp KeyUpDone

KeyUpRight:

    cmp r8d,VK_RIGHT
    jne KeyUpUp
    mov qword ptr [KeyRight],0
    jmp KeyUpDone

KeyUpUp:

    cmp r8d,VK_UP
    jne KeyUpDown
    mov qword ptr [KeyUp],0
    jmp KeyUpDone

KeyUpDown:

    cmp r8d,VK_DOWN
    jne KeyUpDone
    mov qword ptr [KeyDown],0

KeyUpDone:

    xor eax,eax
    ret

wmDestroy:

    xor ecx,ecx
    sub rsp,32
    call PostQuitMessage
    add rsp,32

    xor eax,eax
    ret

WinProc ENDP

InitGraphics PROC widthValue:QWORD,heightValue:QWORD

    mov [BackBufferWidth],rcx
    mov [BackBufferHeight],rdx

    mov BitmapInfo.bmiHeader.biSize,SIZEOF BITMAPINFOHEADER

    mov eax,dword ptr [BackBufferWidth]
    mov BitmapInfo.bmiHeader.biWidth,eax

    mov eax,dword ptr [BackBufferHeight]
    neg eax
    mov BitmapInfo.bmiHeader.biHeight,eax

    mov BitmapInfo.bmiHeader.biPlanes,1
    mov BitmapInfo.bmiHeader.biBitCount,32
    mov BitmapInfo.bmiHeader.biCompression,BI_RGB

    invoke GetDC,NULL
    mov r11,rax

    invoke CreateCompatibleDC,r11
    mov [BackBufferDC],rax

    invoke CreateDIBSection,\
           [BackBufferDC],\
           ADDR BitmapInfo,\
           DIB_RGB_COLORS,\
           ADDR BackBufferMemory,\
           NULL,\
           0

    mov [BackBufferBitmap],rax

    invoke SelectObject,[BackBufferDC],[BackBufferBitmap]

    invoke ReleaseDC,NULL,r11

    ret

InitGraphics ENDP

ClearBackBuffer PROC

    push rdi

    mov rdi,[BackBufferMemory]

    mov rax,[BackBufferWidth]
    imul rax,[BackBufferHeight]
    mov rcx,rax

ClearLoop:

    mov dword ptr [rdi],00000000H
    add rdi,4
    loop ClearLoop

    pop rdi

    ret

ClearBackBuffer ENDP

DrawSprite PROC

    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15

    mov rsi,r8
    mov rdi,r9

    mov r10,[rsp+96]
    mov r11,[rsp+104]
    mov r8,[rsp+112]

    mov r12,rcx
    mov r13,rdx

    xor r14,r14

DrawYLoop:

    cmp r14,r11
    jge DrawDone

    xor r15,r15

DrawXLoop:

    cmp r15,r10
    jge NextSpriteRow

    mov rax,r14
    imul rax,r10
    add rax,r15

    movzx ebx,byte ptr [rsi+rax]

    cmp ebx,0
    je SkipPixel

    mov ecx,dword ptr [rdi+rbx*4]

    xor r9,r9

ScaleYLoop:

    cmp r9,r8
    jge SkipPixel

    xor rbx,rbx

ScaleXLoop:

    cmp rbx,r8
    jge NextScaleY

    mov rdx,r14
    imul rdx,r8
    add rdx,r13
    add rdx,r9

    cmp rdx,0
    jl SkipScaledPixel

    cmp rdx,[BackBufferHeight]
    jge SkipScaledPixel

    mov rax,r15
    imul rax,r8
    add rax,r12
    add rax,rbx

    cmp rax,0
    jl SkipScaledPixel

    cmp rax,[BackBufferWidth]
    jge SkipScaledPixel

    imul rdx,[BackBufferWidth]
    add rdx,rax
    shl rdx,2

    mov rax,[BackBufferMemory]
    add rax,rdx
    mov dword ptr [rax],ecx

SkipScaledPixel:

    inc rbx
    jmp ScaleXLoop

NextScaleY:

    inc r9
    jmp ScaleYLoop

SkipPixel:

    inc r15
    jmp DrawXLoop

NextSpriteRow:

    inc r14
    jmp DrawYLoop

DrawDone:

    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx

    ret

DrawSprite ENDP

DrawTileLayer PROC

    push rbx
    push rsi
    push r12
    push r13
    push r14
    push r15

    mov rsi,rcx

    xor r12,r12

LayerYLoop:

    cmp r12,[MapHeight]
    jge LayerDone

    xor r13,r13

LayerXLoop:

    cmp r13,[MapWidth]
    jge NextLayerRow

    mov rax,r12
    imul rax,[MapWidth]
    add rax,r13

    movzx ebx,byte ptr [rsi+rax]

    cmp ebx,0
    je SkipLayerTile

    mov r14,rbx
    dec r14

    mov rdx,r14
    imul rdx,256
    lea rax,BeachTileSet
    add rdx,rax

    mov rcx,r13
    shl rcx,4

    mov rax,r12
    shl rax,4

    lea r9,BeachPalette

    sub rsp,56

    mov qword ptr [rsp+32],16
    mov qword ptr [rsp+40],16
    mov qword ptr [rsp+48],1

    mov r8,rdx
    mov rdx,rax

    call DrawSprite

    add rsp,56

SkipLayerTile:

    inc r13
    jmp LayerXLoop

NextLayerRow:

    inc r12
    jmp LayerYLoop

LayerDone:

    pop r15
    pop r14
    pop r13
    pop r12
    pop rsi
    pop rbx

    ret

DrawTileLayer ENDP

DrawBackSky PROC

    lea rcx,MapBackSky
    sub rsp,32
    call DrawTileLayer
    add rsp,32

    ret

DrawBackSky ENDP

DrawBackClouds PROC

    lea rcx,MapBackClouds
    sub rsp,32
    call DrawTileLayer
    add rsp,32

    ret

DrawBackClouds ENDP

DrawBackWater PROC

    lea rcx,MapBackWater
    sub rsp,32
    call DrawTileLayer
    add rsp,32

    ret

DrawBackWater ENDP

DrawForeground PROC

    lea rcx,MapForeground
    sub rsp,32
    call DrawTileLayer
    add rsp,32

    ret

DrawForeground ENDP

RenderFrame PROC playerX:QWORD,playerY:QWORD

    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15

    mov r12,rcx
    mov r13,rdx

    sub rsp,32
    call ClearBackBuffer
    add rsp,32

    sub rsp,32
	call DrawBackSky
	add rsp,32

	sub rsp,32
	call DrawBackClouds
	add rsp,32

	sub rsp,32
	call DrawBackWater
	add rsp,32

	sub rsp,32
	call DrawForeground
	add rsp,32

	sub rsp,32
	call DrawBilly
	add rsp,32

    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx

    ret

RenderFrame ENDP

DrawBilly PROC

    mov rcx,r12
    mov rdx,r13

    lea r8,BillyPixels

    mov rax,[BillyCurrentFrame]
    imul rax,[BillyFrameSize]
    add r8,rax

    lea r9,BillyPalette

    sub rsp,56

    mov qword ptr [rsp+32],30
    mov qword ptr [rsp+40],40
    mov qword ptr [rsp+48],1

    call DrawSprite

    add rsp,56

    ret

DrawBilly ENDP

Collision PROC newX:QWORD,newY:QWORD

    push rbx
    push rsi

    mov rax,rcx
    add rax,16
    shr rax,5
    mov rbx,rax

    mov rax,rdx
    add rax,16
    shr rax,5

    imul rax,[MapWidth]
    add rax,rbx

    lea rsi,MapForeground
    movzx eax,byte ptr [rsi+rax]

    cmp eax,0
    jne HasCollision

    xor rax,rax
    jmp CollisionDone

HasCollision:

    mov rax,1

CollisionDone:

    pop rsi
    pop rbx

    ret

Collision ENDP

PresentBackBuffer PROC hdcValue:QWORD,clientWidth:QWORD,clientHeight:QWORD

    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15

    mov rbx,rcx
    mov r12,rdx
    mov r13,r8

    cmp r12,0
    je PresentDone

    cmp r13,0
    je PresentDone

    mov eax,r13d
    imul eax,4
    xor edx,edx
    mov ecx,3
    div ecx

    cmp eax,r12d
    jle UseHeight

UseWidth:

    mov r14d,r12d

    mov eax,r12d
    imul eax,3
    xor edx,edx
    mov ecx,4
    div ecx

    mov r15d,eax

    xor esi,esi

    mov eax,r13d
    sub eax,r15d
    shr eax,1
    mov edi,eax

    cmp edi,0
    jle DrawFinal

    invoke PatBlt,\
           rbx,\
           0,\
           0,\
           r12d,\
           edi,\
           BLACKNESS

    mov eax,edi
    add eax,r15d

    invoke PatBlt,\
           rbx,\
           0,\
           eax,\
           r12d,\
           edi,\
           BLACKNESS

    jmp DrawFinal

UseHeight:

    mov r15d,r13d

    mov eax,r13d
    imul eax,4
    xor edx,edx
    mov ecx,3
    div ecx

    mov r14d,eax

    mov eax,r12d
    sub eax,r14d
    shr eax,1
    mov esi,eax

    xor edi,edi

    cmp esi,0
    jle DrawFinal

    invoke PatBlt,\
           rbx,\
           0,\
           0,\
           esi,\
           r13d,\
           BLACKNESS

    mov eax,esi
    add eax,r14d

    invoke PatBlt,\
           rbx,\
           eax,\
           0,\
           esi,\
           r13d,\
           BLACKNESS

DrawFinal:

    invoke SetStretchBltMode,\
           rbx,\
           COLORONCOLOR

    invoke StretchBlt,\
           rbx,\
           esi,\
           edi,\
           r14d,\
           r15d,\
           [BackBufferDC],\
           0,\
           0,\
           dword ptr [BackBufferWidth],\
           dword ptr [BackBufferHeight],\
           SRCCOPY

PresentDone:

    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx

    ret

PresentBackBuffer ENDP

UIntToDec PROC value:QWORD,buffer:QWORD

    push rbx
    push rsi
    push rdi

    mov rax,rcx
    mov rdi,rdx
    mov r9,rdx

    lea rsi,[rdi+31]
    mov byte ptr [rsi],0
    dec rsi

    mov rbx,10
    xor r8,r8

    cmp rax,0
    jne ConvertLoop

    mov byte ptr [rsi],30h
    mov r8,1
    jmp CopyStart

ConvertLoop:

    xor rdx,rdx
    div rbx

    add dl,30h
    mov byte ptr [rsi],dl

    dec rsi
    inc r8

    test rax,rax
    jnz ConvertLoop

CopyStart:

    inc rsi

CopyLoop:

    cmp r8,0
    je CopyDone

    mov al,byte ptr [rsi]
    mov byte ptr [rdi],al

    inc rsi
    inc rdi
    dec r8

    jmp CopyLoop

CopyDone:

    mov byte ptr [rdi],0

    mov rax,rdi
    sub rax,r9

    pop rdi
    pop rsi
    pop rbx

    ret

UIntToDec ENDP

END start