BITS 32
global _entrypoint

%define WIDTH 1280
%define HEIGHT	720
%define NOISE_SIZE 256
%define NOISE_SIZE_BYTES (4 * NOISE_SIZE * NOISE_SIZE)

%include "timeline.inc"

;%include "4klang.inc"
%define SAMPLE_RATE	44100
%define MAX_INSTRUMENTS	6
%define MAX_VOICES 2
%define HLD 1
%define BPM 60.000000
%define MAX_PATTERNS 37
%define PATTERN_SIZE_SHIFT 4
%define PATTERN_SIZE (1 << PATTERN_SIZE_SHIFT)
%define	MAX_TICKS (MAX_PATTERNS*PATTERN_SIZE)
%define	SAMPLES_PER_TICK 11025
%define DEF_LFO_NORMALIZE 0.0000226757
%define	MAX_SAMPLES	(SAMPLES_PER_TICK*MAX_TICKS)
extern __4klang_render@4
;%define SAMPLERATE 44100
;%define SOUND_SAMPLES (SAMPLERATE * 60)

%define GL_CHECK_ERRORS

%ifndef DEBUG
%define FULLSCREEN
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
%ifdef FULLSCREEN
	WINAPI_FUNC ChangeDisplaySettingsA, 8
%endif
	WINAPI_FUNC CreateThread, 24
	WINAPI_FUNC waveOutOpen, 24
	WINAPI_FUNC waveOutWrite, 12
	WINAPI_FUNC waveOutGetPosition, 12
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
	WINAPI_FUNC ExitProcess, 4
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

section .dwvfmt data
wavefmt:
	dw 3 ; wFormatTag = WAVE_FORMAT_IEEE_FLOAT
	dw 2 ; nChannels
	dd SAMPLE_RATE ; nSamplesPerSec
	dd SAMPLE_RATE * 4 * 2; nAvgBytesPerSec
  dw 4 * 2 ; nBlockAlign
  dw 8 * 4 ; wBitsPerSample
  dw 0 ; cbSize

section .dwvhdr data
wavehdr:
	dd sound_buffer ; lpData
	dd MAX_SAMPLES * 2 * 4 ; dwBufferLength
	times 2 dd 0 ; unused stuff
	;dd 0 ; dwFlags TODO WHDR_PREPARED   0x00000002
	dd 2 ; dwFlags WHDR_PREPARED  =  0x00000002
	times 4 dd 0 ; unused stuff
	wavehdr_size EQU ($ - wavehdr)

section .bsndbuf bss
sound_buffer: resd MAX_SAMPLES * 2

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

section .bsignals bss
signals:
	resd 32

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

%if 1
	;CHECK(waveOutOpen(&hWaveOut, WAVE_MAPPER, &WaveFMT, NULL, 0, CALLBACK_NULL));
	push ecx
	push ecx
	push ecx
	push wavefmt
	push -1
	push noise

	;CHECK(waveOutPrepareHeader(hWaveOut, &WaveHDR, sizeof(WaveHDR)));
	;push wavehdr_size
	;push wavehdr
%endif

%ifdef FULLSCREEN
	push 4
	push devmode
%endif

;	CreateThread(0, 0, (LPTHREAD_START_ROUTINE)soundRender, sound_buffer, 0, 0);
	push ecx
	push ecx
	push sound_buffer
	push __4klang_render@4
	push ecx
	push ecx
	call CreateThread

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

	call waveOutOpen
	mov ebp, dword [noise]
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

%if 1
	push wavehdr_size
	push wavehdr
	push ebp
	call waveOutWrite
	;CHECK(waveOutWrite(hWaveOut, &WaveHDR, sizeof(WaveHDR)));
%endif

	push ebp
	push ebp
	push ebp
mainloop:
	mov ebx, esp
	mov dword [ebx], 4
	; waveOutGetPosition(hWaveOut, &mmtime, sizeof(mmtime))
	push 12
	push ebx
	push ebp
	call waveOutGetPosition
	mov eax, dword [esp + 4]
	cmp eax, MAX_SAMPLES * 8
	jge exit

	;xor edx, edx
	;mov ebx, SAMPLE_RATE * 4 * 2 ; ???
	;div ebx
	shr eax, 5 ; to samples

	mov esi, signals

%macro signal_read 3
	xor ecx, ecx
%%sigread_loop:
	movsx edx, byte [%3 + ecx]
	inc ecx
	movzx ebx, byte [%2 + ecx]
	imul ebx, ebx, SAMPLES_PER_TICK
	cmp eax, ebx
	jl %%sigread_compute
	sub eax, ebx
	cmp ecx, %1
	jl %%sigread_loop
%%sigread_compute:
	mov dword [esi], edx
	fild dword [esi] ; ST(0) = v0
	fld st0 ; v0, v0
	movsx edx, byte [%3 + ecx]
	mov dword [esi], edx
	fild dword [esi] ; v1 v0 v0
	fsubrp ; v1-v0 v0
	mov dword [esi], eax
	fild dword [esi] ; t-t0, v1-v0, v0
	fmulp ; (t-t0)*(v1-v0), v0
	mov dword [esi], ebx
	fild dword [esi] ; (t1-t0), (t-t0)*(v1-v0), v0
	fdivp ; (t-t0)*(v1-v0)/(t1-t0), v0
	faddp ; v0 + (t-t0)*(v1-v0)/(t1-t0)
	mov dword [esi], 4
	fild dword [esi]
	fdivp
	fstp dword [esi]
%endmacro

	push eax
	signal_read sig0_n, sig0_t, sig0_v
	pop eax
	add esi, 4
	push eax
	signal_read sig1_n, sig1_t, sig1_v
	pop eax
	add esi, 4
	push eax
	signal_read sig2_n, sig2_t, sig2_v
	pop eax
	add esi, 4
	push eax
	signal_read sig3_n, sig3_t, sig3_v
	pop eax
	add esi, 4
	push eax
	signal_read sig4_n, sig4_t, sig4_v
	pop eax
	add esi, 4
	push eax
	signal_read sig5_n, sig5_t, sig5_v
	pop eax
	add esi, 4
	push eax
	signal_read sig6_n, sig6_t, sig6_v
	pop eax
	add esi, 4
	push eax
	signal_read sig7_n, sig7_t, sig7_v
	pop eax
	add esi, 4
	push eax
	signal_read sig8_n, sig8_t, sig8_v
	pop eax
	add esi, 4
	push eax
	signal_read sig9_n, sig9_t, sig9_v
	pop eax
%if 0
	cmp dword [esp + 4], MAX_SAMPLES * 8
	jge exit
	mov dword [esp], SAMPLE_RATE * 8
	fild dword [esp + 4]
	fild dword [esp]
	fdivp
	fstp dword [esi]
%endif

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

exit:
	call ExitProcess

%if 0
section .ctstsnd code
test_sound_proc:
	nop
	jmp test_sound_proc
%endif
