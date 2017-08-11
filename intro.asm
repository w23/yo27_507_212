BITS 32
global _entrypoint

%define WIDTH 1280
%define HEIGHT	720
%define FULLSCREEN 0

%define ExitProcess _ExitProcess@4
%define ShowCursor _ShowCursor@4
%define CreateWindowExA _CreateWindowExA@48
%define GetDC _GetDC@4
%define ChoosePixelFormat _ChoosePixelFormat@8
%define SetPixelFormat _SetPixelFormat@12
%define wglCreateContext _wglCreateContext@4
%define wglMakeCurrent _wglMakeCurrent@8
%define wglGetProcAddress _wglGetProcAddress@4
%define timeGetTime _timeGetTime@0
%define glClearColor _glClearColor@16
%define glClear _glClear@4
%define SwapBuffers _SwapBuffers@4
%define PeekMessageA _PeekMessageA@20
%define GetAsyncKeyState _GetAsyncKeyState@4

extern ExitProcess
extern ShowCursor
extern CreateWindowExA
extern GetDC
extern ChoosePixelFormat
extern SetPixelFormat
extern wglCreateContext
extern wglMakeCurrent
extern wglGetProcAddress
extern timeGetTime
extern glClearColor
extern glClear
extern SwapBuffers
extern PeekMessageA
extern GetAsyncKeyState

section .data
%if 0
IFDEF FUNC_OFFSETS
	ExitProcess dd ExitProcess@4
	ShowCursor dd ShowCursor@4
	CreateWindowExA dd CreateWindowExA@48
	GetDC dd GetDC@4
	ChoosePixelFormat dd ChoosePixelFormat@8
	SetPixelFormat dd SetPixelFormat@12
	wglCreateContext dd wglCreateContext@4
	wglMakeCurrent dd wglMakeCurrent@8
	wglGetProcAddress dd wglGetProcAddress@4
	timeGetTime dd timeGetTime@0
	glClearColor dd glClearColor@16
	glClear dd glClear@4
	SwapBuffers dd SwapBuffers@4
	PeekMessageA dd PeekMessageA@20
	GetAsyncKeyState dd GetAsyncKeyState@4
ELSE
	ExitProcess EQU ExitProcess@4
	ShowCursor EQU ShowCursor@4
	CreateWindowExA EQU CreateWindowExA@48
	GetDC EQU GetDC@4
	ChoosePixelFormat EQU ChoosePixelFormat@8
	SetPixelFormat EQU SetPixelFormat@12
	wglCreateContext EQU wglCreateContext@4
	wglMakeCurrent EQU wglMakeCurrent@8
	wglGetProcAddress EQU wglGetProcAddress@4
	timeGetTime EQU timeGetTime@0
	glClearColor EQU glClearColor@16
	glClear EQU glClear@4
	SwapBuffers EQU SwapBuffers@4
	PeekMessageA EQU PeekMessageA@20
	GetAsyncKeyState EQU GetAsyncKeyState@4
ENDIF

fcall MACRO func
IFDEF FUNC_OFFSETS
	call dword ptr [ebp + (func - ExitProcess)]
ELSE
	call func
ENDIF
endm
%endif

pixelFormatDescriptor:
	DW	028H
	DW	01H
	DD	025H
	DB	00H
	DB	020H
	DB	00H
	DB	00H
	DB	00H
	DB	00H
	DB	00H
	DB	00H
	DB	08H
	DB	00H
	DB	00H
	DB	00H
	DB	00H
	DB	00H
	DB	00H
	DB	020H
	DB	00H
	DB	00H
	DB	00H
	DB	00H
	DD	00H
	DD	00H
	DD	00H

screenSettings:
	DB 00H
	DW	00H
	DW	00H
	DW	09cH
	DW	00H
	DD	01c0000H
	DW	00H
	DW	00H
	DW	00H
	DW	00H
	DW	00H
	DW	00H
	DB	00H
	DW	00H
	DD	020H
	DD	WIDTH
	DD	HEIGHT
	DD	00H
	DD	00H
	DD	00H
	DD	00H
	DD	00H
	DD	00H
	DD	00H
	DD	00H
	DD	00H
	DD	00H

static:
	db "static", 0

%if 0
IFDEF SEPARATE_STACK
	ShowCursor_args	dd 0
	CreateWindowExA_args dd 0
		;dd 0C018H
		dd static
		dd 0
		dd 90000000H
		dd 0, 0
		dd WIDTH
		dd HEIGHT
		dd 0, 0, 0, 0
	ChoosePixelFormat_args dd pixelFormatDescriptor
	SetPixelFormat_args dd pixelFormatDescriptor
	Args_end db ?
ELSE
ENDIF

.data?
;bss_begin: dd ?
%endif

section .code
_entrypoint:
	;mov ebp, OFFSET ExitProcess
%if 0
IFDEF SEPARATE_STACK
	mov ecx, Args_end - ShowCursor_args
	sub esp, ecx
	mov edi, esp
	mov esi, OFFSET ShowCursor_args
	rep movsb
ELSE
%endif
	xor eax, eax
	mov ebx, WIDTH
	mov ecx, HEIGHT
;	mov edx, OFFSET static
; SetPixelFormat
	push pixelFormatDescriptor
; ChoosePixelFormat
	push pixelFormatDescriptor
; CreateWindowExA
	push eax
	push eax
	push eax
	push eax
	push ecx
	push ebx
	push eax
	push eax
	push 090000000H
	push eax
	push static
	push eax
; ShowCursor
	push eax

%define fcall call

	fcall ShowCursor
	fcall CreateWindowExA
	push eax
	fcall GetDC
	push eax
	push eax
	pop ebx
	fcall ChoosePixelFormat
	push eax
	push ebx
	fcall SetPixelFormat
	push ebx
	push ebx
	fcall wglCreateContext
	push eax
	push ebx
	fcall wglMakeCurrent

	; TODO wglGetProcAddress

	fcall timeGetTime
	push ebx
	mov ebx, eax

mainloop:
	fcall timeGetTime
	sub eax, ebx
	push eax
	fild dword [esp]
	mov dword [esp], 1000
	fidiv dword [esp]
	fsin
	fstp dword [esp]
	pop eax

	push eax
	push eax
	push eax
	push eax
	fcall glClearColor
	push 000004000H
	fcall glClear

	pop ebx
	push ebx
	push ebx
	fcall SwapBuffers
	push 01bH
	fcall GetAsyncKeyState
	jz mainloop

exit:
	fcall ExitProcess
