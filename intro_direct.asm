BITS 32
global _entrypoint

%define WIDTH 1280
%define HEIGHT	720
%define FULLSCREEN
%define NOISE_SIZE 256
%define NOISE_SIZE_BYTES (4 * NOISE_SIZE * NOISE_SIZE)

%define GL_CHECK_ERRORS

%ifndef _DEBUG
%define GLCHECK
%else
%macro GLCHECK 0
	call glGetError
	test eax, eax
	jz %%ok
	int 3
%%ok:
%endmacro
%endif

GL_TEXTURE_2D EQU 0x0de1
GL_FRAGMENT_SHADER EQU 0x8b30
GL_UNSIGNED_BYTE EQU 0x1401
GL_FLOAT EQU 0x1406
GL_RGBA EQU 0x1908
GL_LINEAR EQU 0x2601
GL_TEXTURE_MIN_FILTER EQU 0x2801
GL_TEXTURE1 EQU 0x84c1
GL_RGBA16F EQU 0x881a
GL_FRAMEBUFFER EQU 0x8D40
GL_COLOR_ATTACHMENT0 EQU 0x8ce0
GL_COLOR_ATTACHMENT1 EQU 0x8ce1

%macro WINAPI_FUNCLIST 0
	WINAPI_FUNC ExitProcess, 4
%ifdef FULLSCREEN
	WINAPI_FUNC ChangeDisplaySettingsA, 8
%endif
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
	WINAPI_FUNC glGetError, 0
%if 0
	WINAPI_FUNC glClearColor, 16
	WINAPI_FUNC glClear, 4
%endif
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

vm_procs:
%macro WINAPI_FUNC 2
  %1 EQU _ %+ %1 %+ @ %+ %2
%endmacro
WINAPI_FUNCLIST
%unmacro WINAPI_FUNC 2

section .bglproc bss
gl_procs:
%macro GL_FUNC 1
%1 %+ _:
%define %1 [%1 %+ _]
	resd 1
%endmacro
GL_FUNCLIST
%unmacro GL_FUNC 1

section .dshead data
%include "header.inc"
section .dsraymarch data
%include "raymarch.inc"
section .dsblurr data
%include "blur_reflection.inc"
section .dscomposite data
%include "composite.inc"
section .dsdof data
%include "dof_tap.inc"
section .dspos data
%include "post.inc"

section .dpfd data
pfd:
	DW	028H,	01H
	DD	025H
	DB	00H, 020H, 00H, 00H, 00H, 00H, 00H, 00H, 08H, 00H, 00H, 00H, 00H, 00H
	DB	00H, 020H, 00H, 00H, 00H, 00H
	DD	00H, 00H, 00H

%ifdef FULLSCREEN
section .ddevmod data
devmode:
	times 9 dd 0
	db 0x9c, 0, 0, 0
	db 0, 0, 0x1c, 0
	times 15 dd 0
	DD	020H, WIDTH, HEIGHT
	times 10 dd 0
%endif

section .dstrs data
%ifdef DEBUG
static: db "static", 0
%endif
S: db 'S', 0
F: db 'F', 0

section .bnoise bss
dev_null: resd 7
noise: resb NOISE_SIZE_BYTES

section .dsptrs data
src_raymarch:
	dd _header_glsl
	dd _raymarch_glsl
src_reflect_blur:
	dd _header_glsl
	dd _blur_reflection_glsl
src_composite:
	dd _header_glsl
	dd _composite_glsl
src_dof:
	dd _header_glsl
	dd _dof_tap_glsl
src_post:
	dd _header_glsl
	dd _post_glsl

section .ddrwbuf data
draw_buffers:
	dd 0x8ce0, 0x8ce1

section .dsmplrs data
samplers:
	dd 0, 1, 2, 3, 4, 5, 6

tex_noise EQU 1
tex_raymarch_primary EQU 2
tex_raymarch_reflect EQU 3
tex_reflect_blur EQU 4
tex_composite EQU 5
tex_dof_near EQU 6
tex_dof_far EQU 7

fb_raymarch EQU 1
fb_reflect_blur EQU 2
fb_composite EQU 3
fb_dof EQU 4

prog_raymarch EQU 1
prog_reflect_blur EQU 2
prog_composite EQU 3
prog_dof EQU 4
prog_post EQU 5

section .bsignals data
signals:
	times 32 dd 5.0

%if 0
section .bmamem bss
main_mem:
%macro declare_main_mem 0
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
addr_m_ %+ %1:
m_ %+ %1 EQU ($-$$)
	resd 1
%endmacro
declare_main_mem
%define MEM(m) \
	[ebp + m]
%define MEMADDR(m) addr_ %+ m
%endif

%macro initTexture 6
	push %1
	push GL_TEXTURE_2D
	call glBindTexture

	push %6
	push %5
	push GL_RGBA
	push 0
	push %3
	push %2
	push %4
	push 0
	push GL_TEXTURE_2D
	call glTexImage2D

	push GL_LINEAR
	push GL_TEXTURE_MIN_FILTER
	push GL_TEXTURE_2D
	call glTexParameteri
%endmacro

%macro initTextureStack 6
	push GL_LINEAR
	push GL_TEXTURE_MIN_FILTER
	push GL_TEXTURE_2D
	;call glTexParameteri

	push %6
	push %5
	push GL_RGBA
	push 0
	push %3
	push %2
	push %4
	push 0
	push GL_TEXTURE_2D
	;call glTexImage2D

	push %1
	push GL_TEXTURE_2D
	;call glBindTexture
%endmacro

%macro initFb 3
	push %1
	push GL_FRAMEBUFFER
	call glBindFramebuffer
	GLCHECK

	push 0
	push %2
	push GL_TEXTURE_2D
	push GL_COLOR_ATTACHMENT0
	push GL_FRAMEBUFFER
	call glFramebufferTexture2D
	GLCHECK

	push 0
	push %3
	push GL_TEXTURE_2D
	push GL_COLOR_ATTACHMENT1
	push GL_FRAMEBUFFER
	call glFramebufferTexture2D
	GLCHECK
%endmacro

%macro compileProgram 2
	push %2
	push 2
	push GL_FRAGMENT_SHADER
	call glCreateShaderProgramv
	; ignore mov %1, eax
	GLCHECK
%endmacro

%macro paintPass 3
	push %2
	push GL_FRAMEBUFFER
	call glBindFramebuffer
	GLCHECK

%ifnum %2
%else
	push draw_buffers
	push %3
	call glDrawBuffers
	GLCHECK
%endif

	push %1
	call glUseProgram
	GLCHECK

	push samplers
	push 7
	push S
	push %1
	call glGetUniformLocation
	push eax
	call glUniform1iv

	push signals
	push 16
	push F
	push %1
	call glGetUniformLocation
	push eax
	call glUniform1fv

	push 1
	push 1
	push byte -1
	push byte -1
	call glRects
%endmacro

section .centry text align=1
_entrypoint:
	xor ecx, ecx

%if 0
	initTextureStack tex_dof_far, WIDTH/2, HEIGHT/2, GL_RGBA16F, GL_FLOAT, 0
	push GL_TEXTURE1+5
	initTextureStack tex_dof_near, WIDTH/2, HEIGHT/2, GL_RGBA16F, GL_FLOAT, 0
	push GL_TEXTURE1+4
	initTextureStack tex_composite, WIDTH, HEIGHT, GL_RGBA16F, GL_FLOAT, 0
	push GL_TEXTURE1+3
	initTextureStack tex_reflect_blur, WIDTH/2, HEIGHT/2, GL_RGBA16F, GL_FLOAT, 0
	push GL_TEXTURE1+2
	initTextureStack tex_raymarch_reflect, WIDTH, HEIGHT, GL_RGBA16F, GL_FLOAT, 0
	push GL_TEXTURE1+1
	initTextureStack tex_raymarch_primary, WIDTH, HEIGHT, GL_RGBA16F, GL_FLOAT, 0
	push GL_TEXTURE1
	initTextureStack tex_noise, NOISE_SIZE, NOISE_SIZE, GL_RGBA, GL_UNSIGNED_BYTE, noise
%endif

	; glGenFramebuffers
	push dev_null
	push 4
	; glGenTextures
	push dev_null
	push 7
	; SetPixelFormat
	push pfd
	; ChoosePixelFormat
	push pfd
	push ecx
	push ecx
	push ecx
	push ecx
	push HEIGHT
	push WIDTH
	push ecx
	push ecx
	push 0x90000000
	push ecx
%ifdef DEBUG
	push static
%else
	push 0xc018
%endif
	push ecx
	push ecx

%ifdef FULLSCREEN
	push 4
	push devmode
%endif

generate_noise:
	; expects ecx zero
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

window_init:
%ifdef FULLSCREEN
	call ChangeDisplaySettingsA
%endif

	call ShowCursor
	call CreateWindowExA
	push eax
	call GetDC
	push eax
	mov edi, eax ; edi is hdc from now on
	call ChoosePixelFormat
	push eax
	push edi
	call SetPixelFormat
	push edi
	call wglCreateContext
	push eax
	push edi
	call wglMakeCurrent
	GLCHECK

gl_proc_loader:
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
	GLCHECK

alloc_resources:
	call glGenTextures
	GLCHECK
	call glGenFramebuffers
	GLCHECK

init_textures:
	initTexture tex_noise, NOISE_SIZE, NOISE_SIZE, GL_RGBA, GL_UNSIGNED_BYTE, noise
	push GL_TEXTURE1
	call glActiveTexture
	initTexture tex_raymarch_primary, WIDTH, HEIGHT, GL_RGBA16F, GL_FLOAT, 0
	push GL_TEXTURE1+1
	call glActiveTexture
	initTexture tex_raymarch_reflect, WIDTH, HEIGHT, GL_RGBA16F, GL_FLOAT, 0
	push GL_TEXTURE1+2
	call glActiveTexture
	initTexture tex_reflect_blur, WIDTH/2, HEIGHT/2, GL_RGBA16F, GL_FLOAT, 0
	push GL_TEXTURE1+3
	call glActiveTexture
	initTexture tex_composite, WIDTH, HEIGHT, GL_RGBA16F, GL_FLOAT, 0
	push GL_TEXTURE1+4
	call glActiveTexture
	initTexture tex_dof_near, WIDTH/2, HEIGHT/2, GL_RGBA16F, GL_FLOAT, 0
	push GL_TEXTURE1+5
	call glActiveTexture
	initTexture tex_dof_far, WIDTH/2, HEIGHT/2, GL_RGBA16F, GL_FLOAT, 0

init_fbs:
	initFb fb_raymarch, tex_raymarch_primary, tex_raymarch_reflect
	initFb fb_reflect_blur, tex_reflect_blur, 0
	initFb fb_composite, tex_composite, 0
	initFb fb_dof, tex_dof_near, tex_dof_far

init_progs:
	compileProgram MEM(m_prog_raymarch), src_raymarch
	compileProgram MEM(m_prog_reflect_blur), src_reflect_blur
	compileProgram MEM(m_prog_composite), src_composite
	compileProgram MEM(m_prog_dof), src_dof
	compileProgram MEM(m_prog_post), src_post

mainloop:
	paintPass prog_raymarch, fb_raymarch, 2
	paintPass prog_reflect_blur, fb_reflect_blur, 1
	paintPass prog_composite, fb_composite, 1
	paintPass prog_dof, fb_dof, 2
	paintPass prog_post, 0, 0

	push edi
	call SwapBuffers

	push 01bH ;GetAsyncKeyState

	push 1
	push 0
	push 0
	push 0
	push 0
	call PeekMessageA
	call GetAsyncKeyState
	jz mainloop

	call ExitProcess
