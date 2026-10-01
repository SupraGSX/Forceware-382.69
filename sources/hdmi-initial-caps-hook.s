.intel_syntax noprefix
.code32
.section .hook,"ax",@progbits
.global _start
.extern bridge
.extern resume
_start:
pushfd
pushad
mov eax,[esp+0x134]
push ebx
push eax
call bridge
add esp,8
.global bridge_return
bridge_return:
popad
popfd
and dword ptr [ebx+0x20],0xfffffffb
mov edi,[esp+0x114]
jmp resume
.section .note.GNU-stack,"",@progbits
