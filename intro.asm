BITS 32
global _entrypoint

%define WIDTH 1280
%define HEIGHT	720
%define FULLSCREEN 0

%macro WINAPI_FUNCLIST 0
	WINAPI_FUNC(ExitProcess, 4)
	WINAPI_FUNC(ShowCursor, 4)
	WINAPI_FUNC(CreateWindowExA, 48)
	WINAPI_FUNC(GetDC, 4)
	WINAPI_FUNC(ChoosePixelFormat, 8)
	WINAPI_FUNC(SetPixelFormat, 12)
	WINAPI_FUNC(wglCreateContext, 4)
	WINAPI_FUNC(wglMakeCurrent, 8)
	WINAPI_FUNC(wglGetProcAddress, 4)
	WINAPI_FUNC(timeGetTime, 0)
	WINAPI_FUNC(glClearColor, 16)
	WINAPI_FUNC(glClear, 4)
	WINAPI_FUNC(SwapBuffers, 4)
	WINAPI_FUNC(PeekMessageA, 20)
	WINAPI_FUNC(GetAsyncKeyState, 4)
%endmacro

%define WINAPI_FUNC(f, s) \
	extern _ %+ f %+ @ %+ s

WINAPI_FUNCLIST

%define WINAPI_FUNC(f, s) \
	f EQU _ %+ f %+ @ %+ s

WINAPI_FUNCLIST

section .data-pfd data
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

section .data-scrstt data
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

section .data-static data
static:
	db "static", 0

Op_PushImm EQU 0
Op_PushBigConst EQU 1
Op_PushMem EQU 2
Op_PopMem EQU 3
Op_Pop EQU 4
Op_Dup EQU 5
Op_Call EQU 6

section .data-vm-bigconst data
vm_big_const:
	dd pixelFormatDescriptor
	dd WIDTH
	dd HEIGHT
	dd 090000000H
	dd static

%macro vmprog 0
	OP(Op_PushBigConst, 0)
	OP(Op_PushBigConst, 0)
	OP(Op_PushImm, 0)
	OP(Op_PushImm, 0)
	OP(Op_PushImm, 0)
	OP(Op_PushImm, 0)
	OP(Op_PushBigConst, 2)
	OP(Op_PushBigConst, 1)
	OP(Op_PushImm, 0)
	OP(Op_PushImm, 0)
	OP(Op_PushBigConst, 3)
	OP(Op_PushImm, 0)
	OP(Op_PushBigConst, 4)
	OP(Op_PushImm, 0)
	OP(Op_PushImm, 0)
	OP(Op_Call, 1)
	OP(Op_Call, 2)
	OP(Op_Dup, 0)
	OP(Op_Call, 3)
	OP(Op_Dup, 0)
	OP(Op_PopMem, 0)
	OP(Op_Call, 4)
	OP(Op_PushMem, 0)
	OP(Op_Call, 5)
	OP(Op_PushMem, 0)
	OP(Op_PushMem, 0)
	OP(Op_Call, 6)
	OP(Op_PushMem, 0)
	OP(Op_Call, 7)
	OP(Op_Call, 0)
%endmacro

section .code-ops data align 1
entry_ops:
%define OP(o, a) db o
vmprog

section .code-args data align 1
entry_args:
%define OP(o, a) db a
vmprog

section .code-mem bss
entry_mem: resb 256

section .data-vm-procs data
vm_procs:
%define WINAPI_FUNC(f, s) \
	dd _ %+ f %+ @ %+ s
WINAPI_FUNCLIST

section .data-vm-opcode-ptrs data
opcodes:
	dd op_push_imm
	dd op_push_big_const
	dd op_push_mem
	dd op_pop_mem
	dd op_pop
	dd op_dup
	dd op_call

section .code-vm-ops text
default abs
op_push_imm:
	push eax
	jmp vmrun
op_push_big_const:
	push dword [vm_big_const + eax * 4]
	jmp vmrun
op_push_mem:
	push dword [ebp + eax * 4]
	jmp vmrun
op_pop_mem:
	pop ecx
	mov [ebp + eax * 4], ecx
	jmp vmrun
op_pop:
	pop ecx
	jmp vmrun
op_dup:
	pop ecx
	push ecx
	push ecx
	jmp vmrun
op_call:
	call [vm_procs + eax * 4]
	mov dword [esp], eax
	jmp vmrun

section .code-vmrun text
	; esi -- next op code (u8)
	; edi -- next op imm arg (u8)
	; ebp -- memory
vmrun:
	movzx eax, byte [edi]
	movzx ecx, byte [esi]
	inc edi
	inc esi
	jmp [opcodes + 4 * ecx]

section .code-entrypoint text
_entrypoint:
	mov esi, entry_ops
	mov edi, entry_args
	mov ebp, entry_mem
	jmp vmrun
%if 0
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
%endif
