.intel_syntax noprefix
.code32
.section .text
.global voltage_admission
voltage_admission:
    call native_os
    test al,al
    jnz native_return
    sub esp,16
    xor eax,eax
    mov dword ptr [esp],0x10010
    mov dword ptr [esp+4],eax
    mov dword ptr [esp+8],eax
    mov dword ptr [esp+12],eax
    lea edx,[esp]
    push edx
    push dword ptr [ebp+8]
    call native_arch
    add esp,8
    test eax,eax
    jnz denied
    cmp dword ptr [esp+4],0x130
    jne denied
    cmp dword ptr [esp+8],7
    je admitted
    cmp dword ptr [esp+8],8
    jne denied
admitted:
    mov eax,1
    jmp cleanup
denied:
    xor eax,eax
cleanup:
    add esp,16
native_return:
    ret
