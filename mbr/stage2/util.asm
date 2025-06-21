%define UTIL_ASM_INC_NO_EXTERN
%include "stage2/util.asm.inc"

bits 32

global memcmp
memcmp: ; int memcmp(void *buf1, void *buf2, uint32_t len)
    push ebp
    mov ebp, esp
    push edi
    push esi

    mov esi, dword [ebp + 8]
    mov edi, dword [ebp + 12]
    mov ecx, dword [ebp + 16]
    and ecx, 0x03
    repe cmpsb
    jne .fail
    mov ecx, dword [ebp + 16]
    shr ecx, 2
    repe cmpsd
    jne .fail

    xor eax, eax
    jmp .exit
.fail:
    mov eax, 1
.exit:
    pop esi
    pop edi
    pop ebp
    ret

global memcpy
memcpy: ; int memcpy(void *dst, void *src, uint32_t len)
    push ebp
    mov ebp, esp
    push edi
    push esi

    mov edi, dword [ebp + 8]
    mov esi, dword [ebp + 12]
    mov ecx, dword [ebp + 16]
    and ecx, 0x03
    repe movsb
    mov ecx, dword [ebp + 16]
    shr ecx, 2
    repe movsd

    xor eax, eax
    jmp .exit
.fail:
    mov eax, 1
.exit:
    pop esi
    pop edi
    pop ebp
    ret

global memset
memset: ; int memset(void *dst, int byte, uint32_t len)
    push ebp
    mov ebp, esp
    push esi

    ; Fill eax with the byte value
    mov cl, byte [ebp + 12]
    mov al, cl
    shl eax, 8
    mov al, cl
    shl eax, 8
    mov al, cl
    shl eax, 8
    mov al, cl

    mov edi, dword [ebp + 8]
    mov ecx, dword [ebp + 16]
    and ecx, 0x03
    repe stosb
    mov ecx, dword [ebp + 16]
    shr ecx, 2
    repe stosd

.exit:
    xor eax, eax
    pop esi
    pop ebp
    ret

global check_cpuid
check_cpuid: ; int check_cpuid()
    ; Try and flip the ID flag bit.
    pushfd
    pushfd
    xor dword [esp], 0x00200000
    popfd
    pushfd
    pop eax
    xor eax, dword [esp]
    popfd ; Restore original flags

    ; eax is zero if the bit could not be changed
    not eax
    and eax, 0x00200000
    shr eax, 21
    ; return eax = 0 if we support cpuid, otherwise 1
    ret

global get_cpu_features
get_cpu_features: ; uint64_t get_cpu_features(void)
    push ebp
    mov ebp, esp

    ; Verify that CPUID works
    call check_cpuid
    cmp eax, 0
    jnz .id_fail

    mov eax, 1
    cpuid
    jmp .done

.id_fail:
    xor edx, edx
    xor eax, eax
.done:
    pop ebp
    ret
