%define SYS_WRITE		1
%define SYS_OPEN		2
%define SYS_CLOSE		3
%define SYS_LSEEK		8
%define SYS_MMAP		9

%define SEEK_END		2
%define O_RDONLY		0
%define PROT_READ		0x1
%define PROT_WRITE		0x2
%define MAP_PRIVATE		0x2

%define ELFMAG			0x464C457F
%define ELFCLASS32		1
%define ELFCLASS64		2

%define O_CREAT			100q
%define O_WRONLY		1q
%define O_TRUNC			1000q
%define ACCESSPERMS		777q

global main
extern puts
extern perror
extern __errno_location
section .text

struc elfhdr
	.ei_mag resd		1	;ELF "magic number"
	.ei_class resb		1	;32-bit = 1 64-bit = 2
	.ei_data resb		1	;little endian = 1 big endian = 2
	.ei_version resb	1	;elf version
	.ei_osabi resb		1	;OS version
	.ei_abiversion resb	1	;ABI version
	.ei_pad resb		7	;reserved padding

	.e_type resw		1	;Elf64_Half e_type
	.e_machine resw		1	;Elf64_Half e_machine
	.e_version resd		1	;Elf64_Word e_version
	.e_entry resq		1	;Elf64_Addr e_entry
	.e_phoff resq		1	;Elf64_Off e_phoff
	.e_shoff resq		1	;Elf64_Off e_shoff
	.e_flags resd		1	;Elf64_Word e_flags
	.e_ehsize resw		1	;Elf64_Half e_ehsize
	.e_phentsize resw	1	;Elf64_Half e_phentisze
	.e_phnum resw		1	;Elf64_Half e_phnum
	.e_shentsize resw	1	;Elf64_Half e_shentsize
	.e_shnum resw		1	;Elf64_Half e_shnum
	.e_shstrndx resw	1	;Elf64_Half e_shstrndx
	.end resb			1	;end
endstruc

struc phdr
	.p_type resd		1	;Elf64_Word p_type
	.p_flags resd		1	;Elf64_Word p_flags
	.p_offset resq		1	;Elf64_Off p_offset
	.p_vaddr resq		1	;Elf64_Addr p_vaddr
	.p_paddr resq		1	;Elf64_Addr p_paddr
	.p_filesz resq		1	;Elf64_Xword p_filesz
	.p_memsz resq		1	;Elf64_Xword p_memsz
	.p_align resq		1	;Elf64_Xword p_align
endstruc

main:
    push r12                ; save callee-save registers
    push r13
    push r14

    cmp rdi, 2
    jne print_usage

open_file:
    mov rdi, [rsi + 8]     ; av[0]
    mov rsi, O_RDONLY		; O_RDONLY
	xor rdx, rdx
    mov rax, SYS_OPEN		; open syscall 
    syscall
    cmp rax, 0
    js perror_open

get_file_size:
    mov r13, rax            ; r13 stores fd
    mov rdi, rax            ; fd
    xor rsi, rsi            ; offset
    mov rdx, SEEK_END       ; SEEK_END
    mov rax, SYS_LSEEK      ; lseek syscall
    syscall
    cmp rax, 0
    jng perror_lseek

mmap_file:
    xor rdi, rdi            ; addr == NULL
	mov r12, rax			; r12 stores size of file
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

check_elf_header:
.magic_number:
	cmp dword [r14], ELFMAG
	jne notelf

.padding:
	cmp dword [r14 + elfhdr.ei_pad], 0xCAFEBABE
	je louisawashere
;.type:
;	cmp word [r14 + 0x10], 0x02
;	jne wrongtype
.class:
	cmp byte [r14 + elfhdr.ei_class], ELFCLASS64
	je elfclass64
	cmp byte [r14 + elfhdr.ei_class], ELFCLASS32
	je elfclass32
	jmp notclass

elfclass64:
.save_entrypoint:
	mov rdi, [r14 + elfhdr.e_phoff]				;program header offset
	mov r13, [r14 + elfhdr.e_entry]				;store original entrypoint
try_segment_padding:
	xor rcx, rcx
	mov cx, [r14 + elfhdr.e_phnum]				;store number of program header entries

	.loop:

	dec rcx
	; avancer de de phdr en phdr
	; regarder si PT_LOAD 
	; checker les permissions
	; calculer la taille du padding
	; si possible, inject
	; sinon essayer autre chose

woody:
.create:
	mov rdi, WOODY
	mov rsi, O_CREAT
	or rsi, O_TRUNC
	or rsi, O_WRONLY
	mov rdx, ACCESSPERMS
	mov rax, SYS_OPEN
	syscall
	cmp rax, 0
	js perror_open
.write:
	mov rdi, rax
	mov rsi, r14
	mov rdx, r12
	mov rax, SYS_WRITE
	syscall
	cmp rax, r12
	jne perror_write
.close:
	mov rax, SYS_CLOSE
	syscall
	cmp rax, 0
	jne perror_close

notclass:
	mov rdi, wrongclass
	jmp print

wrongtype:
	mov rdi, notexec
	jmp print

louisawashere:
	mov rdi, alreadyinfected
	jmp print

elfclass32:
	mov rdi, is32
	jmp print

perror:
	call perror
	mov rdi, rax
	call puts
	jmp exit
	    
perror_write:
    mov rdi, error_write
    jmp print

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

success:
	mov rdi, wow
	jmp print

notelf:
	mov rdi, noo
	jmp print

print:
    call puts

exit:
    pop r14
    pop r13
    pop r12
    ret

section .data
WOODY db "woody", 0x0
usage db "./woody_woodpacker [ELF64 executable]", 0x0
error_open db "error open", 0x0
error_lseek db "error lseek", 0x0
error_mmap db "error mmap", 0x0
error_close db "error close", 0x0
error_write db "error write", 0x0
wow db "wow c'est un elf", 0x0
noo db "not an elf", 0x0
is64 db "is 64", 0x0
is32 db "is 32", 0x0
alreadyinfected db "This executable was already infected!", 0x0
notexec db "this is not an executable", 0x0
wrongclass db "wrong class for elf", 0x0
