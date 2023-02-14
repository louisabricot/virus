%define SYS_OPEN 2
%define SYS_CLOSE 3
%define SYS_LSEEK 8
%define SYS_MMAP 9
%define SEEK_END 2
%define O_RDONLY 0
%define PROT_READ 0x1
%define PROT_WRITE 0x2
%define MAP_PRIVATE 0x2

global main
extern puts
extern perror
extern __errno_location
section .text

main:
    push r12                ; save callee-save registers
    push r13
    push r14

    cmp rdi, 2
    jne print_usage

open_file:
    mov r12, [rsi + 8]     ; r12 stores name of file
    mov rdi, [rsi + 8]     ; av[0]
    mov rsi, O_RDONLY		; O_RDONLY
	mov rdx, 0
    mov rax, SYS_OPEN		; open syscall 
    syscall
    cmp rax, 0
    js perror_open

get_file_size:
    mov r13, rax            ; r13 stores fd
    mov rdi, rax            ; fd
    mov rsi, 0              ; offset
    mov rdx, SEEK_END       ; SEEK_END
    mov rax, SYS_LSEEK      ; lseek syscall
    syscall
    cmp rax, 0
    jng perror_lseek

mmap_file:
    xor rdi, rdi            ; addr == NULL
    mov rsi, rax            ; file size
    mov rdx, PROT_READ      ; PROT_READ
    or rdx, PROT_WRITE      ; PROT_WRITE
    mov r10, MAP_PRIVATE    ; MAP_PRIVATE
    mov r8, r13             ; fd
    xor r9, r9              ; offset == 0
	mov rax, SYS_MMAP
    syscall
    cmp rax, 0
    js perror
    mov r14, rax            ; r14 stores mmap

close_file:
    mov rdi, r13            ; fd
    mov rax, SYS_CLOSE      ; close syscall
    syscall
    cmp rax, 0
    js perror_close
	jmp exit

perror:
	call perror
	mov rdi, rax
	call puts
	jmp exit
	    
perror_close:
    mov rdi, error_close
    jmp print

perror_mmap:
    mov rdi, error_mmap
    jmp print

perror_lseek:
    mov rdi, error_lseek
    jmp print

perror_open:
    mov rdi, error_open
    jmp print

print_usage:
    mov rdi, usage
    jmp print

print:
    call puts

exit:
    pop r14
    pop r13
    pop r12
    ret

section .data
usage db "./woody_woodpacker [ELF64 executable]", 0x0
error_open db "error open", 0x0
error_lseek db "error lseek", 0x0
error_mmap db "error mmap", 0x0
error_close db "error close", 0x0
