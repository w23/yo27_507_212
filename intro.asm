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

section .dglstr data align=1
gl_proc_names:
%macro GL_FUNC 1
%defstr %[%1 %+ __str] %1
	db %1 %+ __str, 0
%endmacro
GL_FUNCLIST
%unmacro GL_FUNC 1
	db 0

section .dproc data
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

section .bnoise bss
noise: resb NOISE_SIZE_BYTES

section .dpfd data
pixelFormatDescriptor:
	DW	028H,	01H
	DD	025H
	DB	00H, 020H, 00H, 00H, 00H, 00H, 00H, 00H, 08H, 00H, 00H, 00H, 00H, 00H
	DB	00H, 020H, 00H, 00H, 00H, 00H
	DD	00H, 00H, 00H

section .dscrset data
screenSettings:
	DB	00H
	DW	00H, 00H, 09cH, 00H
	DD	01c0000H
	DW	00H, 00H, 00H, 00H, 00H, 00H
	DB	00H
	DW	00H
	DD	020H, WIDTH, HEIGHT
	times 10 dd 0

section .dstatic data
static:
	db "static", 0

Op_PushImm EQU 0
Op_PushConst EQU 1
Op_PushMem EQU 2
Op_PopMem EQU 3
Op_Pop EQU 4
Op_Dup EQU 5
Op_Call EQU 6
Op_CallPush EQU 7
Op_Jmp EQU 8
Op_AddImm EQU 9

section .dvmconst data
vm_big_const:
%macro declare_const 0
	CONST noise_size, NOISE_SIZE
	CONST width2, WIDTH/2
	CONST height2, HEIGHT/2
	CONST width, WIDTH
	CONST height, HEIGHT
	CONST pfd, pixelFormatDescriptor
	CONST winflags, 090000000H
	CONST static, static
	CONST noise, noise
	CONST mainloop, mainloop
	CONST gl_proc_loader, gl_proc_loader
	CONST tex_slots, tex_noise
	CONST fb_slots, fb_raymarch
	CONST GL_TEXTURE_2D, 0x0de1
	CONST GL_UNSIGNED_BYTE, 0x1401
	CONST GL_FLOAT, 0x1406
	CONST GL_RGBA, 0x1908
	CONST GL_LINEAR, 0x2601
	CONST GL_TEXTURE_MIN_FILTER, 0x2801
	CONST GL_TEXTURE1, 0x84c1
	CONST GL_RGBA16F, 0x881a
	CONST GL_FRAMEBUFFER, 0x8D40
	CONST GL_COLOR_ATTACHMENT0, 0x8ce0
	CONST GL_COLOR_ATTACHMENT1, 0x8ce1
%endmacro
%macro CONST 2
c_ %+ %1 EQU ($-$$)/4
	dd %2
%endmacro
declare_const

section .bmamem bss
main_mem:
%macro declare_main_mem 0
	MEMVAR hdc
	MEMVAR tex_noise
	MEMVAR tex_raymarch_primary
	MEMVAR tex_raymarch_reflect
	MEMVAR tex_reflect_blur
	MEMVAR tex_composite
	MEMVAR tex_dof_near
	MEMVAR tex_dof_far
	MEMVAR fb_raymarch
	MEMVAR fb_reflect_blur
	MEMVAR fb_composite
	MEMVAR fb_dof
	MEMVAR prog_raymarch
	MEMVAR prog_reflect_blur
	MEMVAR prog_composite
	MEMVAR prog_dof
	MEMVAR prog_post
%endmacro
%macro MEMVAR 1
%1:
m_ %+ %1 EQU ($-$$)/4
	resd 1
%endmacro
declare_main_mem

%macro initTexture 6
	OP(Op_PushMem, %1)
	OP(Op_PushConst, c_GL_TEXTURE_2D)
	OP(Op_Call, glBindTexture)

%if %6 == 0
	OP(Op_PushImm, %6); c_noise)
%else
	OP(Op_PushConst, %6); c_noise)
%endif
	OP(Op_PushConst, %5);c_GL_UNSIGNED_BYTE)
	OP(Op_PushConst, c_GL_RGBA)
	OP(Op_PushImm, 0)
	OP(Op_PushConst, %3); c_noise_size)
	OP(Op_PushConst, %2); c_noise_size)
	OP(Op_PushConst, %4); _GL_RGBA)
	OP(Op_PushImm, 0)
	OP(Op_PushConst, c_GL_TEXTURE_2D)
	OP(Op_Call, glTexImage2D)

	OP(Op_PushConst, c_GL_LINEAR)
	OP(Op_PushConst, c_GL_TEXTURE_MIN_FILTER)
	OP(Op_PushConst, c_GL_TEXTURE_2D)
	OP(Op_Call, glTexParameteri)
%endmacro

%macro initFb 3
	OP(Op_PushMem, %1)
	OP(Op_PushConst, c_GL_FRAMEBUFFER)
	OP(Op_Call, glBindFramebuffer)

	OP(Op_PushImm, 0)
	OP(Op_PushMem, %2)
	OP(Op_PushConst, c_GL_TEXTURE_2D)
	OP(Op_PushConst, c_GL_COLOR_ATTACHMENT0)
	OP(Op_PushConst, c_GL_FRAMEBUFFER)
	OP(Op_Call, glFramebufferTexture2D)

%if %3 != 0
	OP(Op_PushImm, 0)
	OP(Op_PushMem, %3)
	OP(Op_PushConst, c_GL_TEXTURE_2D)
	OP(Op_PushConst, c_GL_COLOR_ATTACHMENT1)
	OP(Op_PushConst, c_GL_FRAMEBUFFER)
	OP(Op_Call, glFramebufferTexture2D)
%endif
%endmacro

%macro entry_prog 0
	OP(Op_PushConst, c_pfd)
	OP(Op_PushConst, c_pfd)
	OP(Op_PushImm, 0)
	OP(Op_PushImm, 0)
	OP(Op_PushImm, 0)
	OP(Op_PushImm, 0)
	OP(Op_PushConst, c_height)
	OP(Op_PushConst, c_width)
	OP(Op_PushImm, 0)
	OP(Op_PushImm, 0)
	OP(Op_PushConst, c_winflags)
	OP(Op_PushImm, 0)
	OP(Op_PushConst, c_static)
	OP(Op_PushImm, 0)
	OP(Op_PushImm, 0)
	OP(Op_Call, ShowCursor)
	OP(Op_CallPush, CreateWindowExA)
	OP(Op_CallPush, GetDC)
	OP(Op_Dup, 0)
	OP(Op_PopMem, m_hdc)
	OP(Op_CallPush, ChoosePixelFormat)
	OP(Op_PushMem, m_hdc)
	OP(Op_Call, SetPixelFormat)
	OP(Op_PushMem, m_hdc)
	OP(Op_PushMem, m_hdc)
	OP(Op_CallPush, wglCreateContext)
	OP(Op_PushMem, m_hdc)
	OP(Op_Call, wglMakeCurrent)

	OP(Op_PushConst, c_gl_proc_loader)
	OP(Op_Jmp, 0)

	OP(Op_PushConst, c_tex_slots)
	OP(Op_PushImm, 7)
	OP(Op_Call, glGenTextures)

	OP(Op_PushConst, c_fb_slots)
	OP(Op_PushImm, 4)
	OP(Op_Call, glGenFramebuffers)

	initTexture m_tex_noise, c_noise_size, c_noise_size, c_GL_RGBA, c_GL_UNSIGNED_BYTE, c_noise

	OP(Op_PushConst, c_GL_TEXTURE1)
	OP(Op_Dup, 0)

	OP(Op_Call, glActiveTexture)
	initTexture m_tex_raymarch_primary, c_width, c_height, c_GL_RGBA16F, c_GL_FLOAT, 0

	OP(Op_AddImm, 1)
	OP(Op_Dup, 0)
	OP(Op_Call, glActiveTexture)
	initTexture m_tex_raymarch_reflect, c_width, c_height, c_GL_RGBA16F, c_GL_FLOAT, 0
	OP(Op_AddImm, 1)
	OP(Op_Dup, 0)
	OP(Op_Call, glActiveTexture)
	initTexture m_tex_reflect_blur, c_width2, c_height2, c_GL_RGBA16F, c_GL_FLOAT, 0
	OP(Op_AddImm, 1)
	OP(Op_Dup, 0)
	OP(Op_Call, glActiveTexture)
	initTexture m_tex_composite, c_width, c_height, c_GL_RGBA16F, c_GL_FLOAT, 0
	OP(Op_AddImm, 1)
	OP(Op_Dup, 0)
	OP(Op_Call, glActiveTexture)
	initTexture m_tex_dof_near, c_width2, c_height2, c_GL_RGBA16F, c_GL_FLOAT, 0
	OP(Op_AddImm, 1)
	OP(Op_Dup, 0)
	OP(Op_Call, glActiveTexture)
	initTexture m_tex_dof_far, c_width2, c_height2, c_GL_RGBA16F, c_GL_FLOAT, 0

	initFb m_fb_raymarch, m_tex_raymarch_primary, m_tex_raymarch_reflect
	initFb m_fb_reflect_blur, m_tex_reflect_blur, 0
	initFb m_fb_composite, m_tex_composite, 0
	initFb m_fb_dof, m_tex_dof_near, m_tex_dof_far

%if 0
%endif

	OP(Op_PushConst, c_mainloop)
	OP(Op_Jmp, 0)
%endmacro

%macro mainloop_prog 0
	OP(Op_PushMem, m_hdc)
	OP(Op_Call, SwapBuffers)
	OP(Op_PushImm, 1)
	OP(Op_PushImm, 0)
	OP(Op_PushImm, 0)
	OP(Op_PushImm, 0)
	OP(Op_PushImm, 0)
	OP(Op_Call, PeekMessageA)
	OP(Op_PushConst, c_mainloop)
	OP(Op_Jmp, 0)
%endmacro

section .dopentry data align=1
entry_ops:
%define OP(o, a) db o
entry_prog
section .dargentry data align=1
entry_args:
%define OP(o, a) db a
entry_prog

section .doploop data align=1
mainloop_ops:
%define OP(o, a) db o
mainloop_prog
section .dargloop data align=1
mainloop_args:
%define OP(o, a) db a
mainloop_prog

section .dvmops data
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
	dd op_add_imm

section .dvmrunptr data
vmrun_ptr: dd vmrun

section .cvmops text align=1
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
op_add_imm:
	add [esp], eax
	jmp [vmrun_ptr]

section .cvmrun text align=1
	; esi -- next op code (u8)
	; edi -- next op imm arg (u8)
	; ebp -- memory
vmrun:
	movzx eax, byte [edi]
	movzx ecx, byte [esi]
	inc esi
	inc edi
	jmp [opcodes + 4 * ecx]

section .centry text align=1
_entrypoint:
	mov esi, entry_ops
	mov edi, entry_args
	mov ebp, main_mem
	jmp [vmrun_ptr]

;section .cglpld text align=1
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

return_to_bytecode:
	popad
	jmp [vmrun_ptr]

;section .cmainloop text align=1
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
