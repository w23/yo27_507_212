BITS 32
global _entrypoint

%define WIDTH 1280
%define HEIGHT	720
%define FULLSCREEN 0

%macro WINAPI_FUNCLIST 0
	WINAPI_FUNC ExitProcess, 4
	WINAPI_FUNC ShowCursor, 4
	WINAPI_FUNC CreateWindowExA, 48
	WINAPI_FUNC GetDC, 4
	WINAPI_FUNC ChoosePixelFormat, 8
	WINAPI_FUNC SetPixelFormat, 12
	WINAPI_FUNC wglCreateContext, 4
	WINAPI_FUNC wglMakeCurrent, 8
	WINAPI_FUNC wglGetProcAddress, 4
	WINAPI_FUNC timeGetTime, 0
	WINAPI_FUNC glClearColor, 16
	WINAPI_FUNC glClear, 4
	WINAPI_FUNC SwapBuffers, 4
	WINAPI_FUNC PeekMessageA, 20
	WINAPI_FUNC GetAsyncKeyState, 4
%endmacro

%macro WINAPI_FUNC 2
	extern _ %+ %1 %+ @ %+ %2
%endmacro
WINAPI_FUNCLIST
%unmacro WINAPI_FUNC 2

section .data-vm-procs data
vm_procs:
%macro WINAPI_FUNC 2
%1 %+ _:
  %1 EQU ($-$$)/4
	dd _ %+ %1 %+ @ %+ %2
%endmacro
WINAPI_FUNCLIST
%unmacro WINAPI_FUNC 2

;%define WINAPI_FUNC(f, s) \
;	f EQU _ %+ f %+ @ %+ s
;WINAPI_FUNCLIST

section .data-pfd data
pixelFormatDescriptor:
	DW	028H,	01H
	DD	025H
	DB	00H, 020H, 00H, 00H, 00H, 00H, 00H, 00H, 08H, 00H, 00H, 00H, 00H, 00H
	DB	00H, 020H, 00H, 00H, 00H, 00H
	DD	00H, 00H, 00H

section .data-scrstt data
screenSettings:
	DB	00H
	DW	00H, 00H, 09cH, 00H
	DD	01c0000H
	DW	00H, 00H, 00H, 00H, 00H, 00H
	DB	00H
	DW	00H
	DD	020H, WIDTH, HEIGHT
	times 10 dd 0

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
Op_CallPush EQU 7
Op_Jmp EQU 8

section .data-vm-bigconst data
vm_big_const:
	dd pixelFormatDescriptor
	dd WIDTH
	dd HEIGHT
	dd 090000000H
	dd static
	dd mainloop
	dd 000004000H

%macro entry_prog 0
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
	OP(Op_Call, ShowCursor)
	OP(Op_CallPush, CreateWindowExA)
	OP(Op_CallPush, GetDC)
	OP(Op_Dup, 0)
	OP(Op_PopMem, 0)
	OP(Op_CallPush, ChoosePixelFormat)
	OP(Op_PushMem, 0)
	OP(Op_Call, SetPixelFormat)
	OP(Op_PushMem, 0)
	OP(Op_PushMem, 0)
	OP(Op_CallPush, wglCreateContext)
	OP(Op_PushMem, 0)
	OP(Op_Call, wglMakeCurrent)
	OP(Op_PushBigConst, 5)
	OP(Op_Jmp, 0)
%endmacro

%macro mainloop_prog 0
	OP(Op_PushBigConst, 6)
	OP(Op_Call, glClear)
	OP(Op_PushMem, 0)
	OP(Op_Call, SwapBuffers)
	OP(Op_PushImm, 1)
	OP(Op_PushImm, 0)
	OP(Op_PushImm, 0)
	OP(Op_PushImm, 0)
	OP(Op_PushImm, 0)
	OP(Op_Call, PeekMessageA)
	OP(Op_PushBigConst, 5)
	OP(Op_Jmp, 0)
%endmacro

section .code-entry-ops data align 1
entry_ops:
%define OP(o, a) db o
entry_prog

section .code-entry-args data align 1
entry_args:
%define OP(o, a) db a
entry_prog

section .code-mainloop-ops data align 1
mainloop_ops:
%define OP(o, a) db o
mainloop_prog

section .code-mainloop-args data align 1
mainloop_args:
%define OP(o, a) db a
mainloop_prog

section .code-mem bss
main_mem: resb 256

section .data-vm-opcode-ptrs data
opcodes:
	dd op_push_imm
	dd op_push_big_const
	dd op_push_mem
	dd op_pop_mem
	dd op_pop
	dd op_dup
	dd op_call
	dd op_callpush
	dd op_jmp

section .data-vmrun-ptr data
vmrun_ptr: dd vmrun

section .code-vm-ops text
default abs
op_push_imm:
	push eax
	jmp [vmrun_ptr]
op_push_big_const:
	push dword [vm_big_const + eax * 4]
	jmp [vmrun_ptr]
op_push_mem:
	push dword [ebp + eax * 4]
	jmp [vmrun_ptr]
op_pop_mem:
	pop ecx
	mov [ebp + eax * 4], ecx
	jmp [vmrun_ptr]
op_pop:
	pop ecx
	jmp [vmrun_ptr]
op_dup:
	pop ecx
	push ecx
	push ecx
	jmp [vmrun_ptr]
op_call:
	call [vm_procs + eax * 4]
	jmp [vmrun_ptr]
op_callpush:
	call [vm_procs + eax * 4]
	push eax
	;mov dword [esp], eax
	jmp [vmrun_ptr]
op_jmp:
	pop eax
	jmp eax

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
	mov ebp, main_mem
	jmp vmrun

mainloop:
	push 01bH
	call [GetAsyncKeyState_]
	jz mainloop_do
	call [ExitProcess_]

mainloop_do:
	mov esi, mainloop_ops
	mov edi, mainloop_args
	mov ebp, main_mem
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
