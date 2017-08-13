BITS 32
global _entrypoint

%define WIDTH 1280
%define HEIGHT	720
%define FULLSCREEN 0
%define NOISE_SIZE 256
%define NOISE_SIZE_BYTES (4 * NOISE_SIZE * NOISE_SIZE)

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
	WINAPI_FUNC SwapBuffers, 4
	WINAPI_FUNC PeekMessageA, 20
	WINAPI_FUNC GetAsyncKeyState, 4
	WINAPI_FUNC glGenTextures, 8
	WINAPI_FUNC glBindTexture, 8
	WINAPI_FUNC glTexImage2D, 36
	WINAPI_FUNC glTexParameteri, 12
	WINAPI_FUNC glRects, 16
%endmacro

%macro WINAPI_FUNC 2
	extern _ %+ %1 %+ @ %+ %2
%endmacro
WINAPI_FUNCLIST
%unmacro WINAPI_FUNC 2

%macro GL_FUNCLIST 0
	GL_FUNC glCreateShaderProgramv
	GL_FUNC glUseProgram
	GL_FUNC glGetUniformLocation
	GL_FUNC glUniform1iv
	GL_FUNC glUniform1fv
	GL_FUNC glGenFramebuffers
	GL_FUNC glBindFramebuffer
	GL_FUNC glFramebufferTexture2D
	GL_FUNC glDrawBuffers
	GL_FUNC glActiveTexture
%endmacro

section .data-gl-strings data align=1
gl_proc_names:
%macro GL_FUNC 1
%defstr %[%1 %+ __str] %1
	db %1 %+ __str, 0
%endmacro
GL_FUNCLIST
%unmacro GL_FUNC 1
	db 0

section .data-vm-procs data
vm_procs:
%macro WINAPI_FUNC 2
%1 %+ _:
  %1 EQU ($-$$)/4
	dd _ %+ %1 %+ @ %+ %2
%endmacro
WINAPI_FUNCLIST
%unmacro WINAPI_FUNC 2
gl_procs:
%macro GL_FUNC 1
%1 %+ _:
	%1 EQU ($-$$)/4
	dd 0
%endmacro
GL_FUNCLIST
%unmacro GL_FUNC 1

section .bss-noise bss
noise: resb NOISE_SIZE_BYTES

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
	dd gl_proc_loader

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

	OP(Op_PushBigConst, 6)
	OP(Op_Jmp, 0)



	OP(Op_PushBigConst, 5)
	OP(Op_Jmp, 0)
%endmacro

%macro mainloop_prog 0
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

section .code-entry-ops data align=1
entry_ops:
%define OP(o, a) db o
entry_prog
section .code-entry-args data align=1
entry_args:
%define OP(o, a) db a
entry_prog

section .code-mainloop-ops data align=1
mainloop_ops:
%define OP(o, a) db o
mainloop_prog
section .code-mainloop-args data align=1
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

section .code-vm-ops text align=1
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

section .code-vmrun text align=1
	; esi -- next op code (u8)
	; edi -- next op imm arg (u8)
	; ebp -- memory
vmrun:
	movzx eax, byte [edi]
	movzx ecx, byte [esi]
	inc esi
	inc edi
	jmp [opcodes + 4 * ecx]

section .code-entrypoint text align=1
_entrypoint:
	mov esi, entry_ops
	mov edi, entry_args
	mov ebp, main_mem
	jmp [vmrun_ptr]

;section .code-gl-proc-loader text align=1
gl_proc_loader:
	pushad
	mov esi, gl_proc_names
	mov ebx, gl_procs
gl_proc_loader_loop:
	push esi
	call _wglGetProcAddress@4
	mov [ebx], eax
	lea ebx, [ebx + 4]
gl_proc_skip_until_zero:
	mov al, [esi]
	inc esi
	test al, al
	jnz gl_proc_skip_until_zero
	cmp [esi], al
	jnz gl_proc_loader_loop

generate_noise:
%if 1
	xor eax, eax
	mov ebx, noise
	mov ecx, NOISE_SIZE_BYTES
noise_loop:
	imul eax, eax, 0x19660d
	add eax, 0x3c6ef35f
	mov edx, eax
	shr edx, 12
	mov [noise + ecx], dl
	loop noise_loop
%else
	xor ecx, ecx
	xor edx, edx
;8B CD MOV ECX, EBP
;8B D5 MOV EDX, EBP
noise_loop:
	IMUL ECX, ECX, 0x19660D
	ADD ECX, 0x3C6EF35F
	MOV EAX, ECX
	SHR EAX, 0x12
	MOV [EDX+noise], AL
	INC EDX
	CMP EDX, NOISE_SIZE_BYTES
	JL noise_loop
%endif

%if 0
	push main_mem + 8
	push 7
	call _glGenTextures@8

	push main_mem + 8 + 7 * 4
	push 6
	call glGenFramebuffers
%endif

return_to_bytecode:
	popad
	jmp [vmrun_ptr]

;section .code-mainloop text align=1
mainloop:
	push 01bH ; TODO bytecode
	call _GetAsyncKeyState@4
	jz mainloop_do
	call _ExitProcess@4

mainloop_do:
	mov esi, mainloop_ops
	mov edi, mainloop_args
	mov ebp, main_mem
	jmp [vmrun_ptr]
