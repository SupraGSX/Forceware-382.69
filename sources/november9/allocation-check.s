.intel_syntax noprefix
.code32
.section .text
.global guard107,guard108
# Both factories hold only their saved EDI/ESI at the allocation return.
# Preserve every success-path input and flags; never publish an absent object.
guard107:
 pushfd
 test eax,eax
 jz no_memory
 popfd
 push 0x190
 jmp 0xec03b1
guard108:
 pushfd
 test eax,eax
 jz no_memory
 popfd
 push 0x1c0
 jmp 0x10595e7
no_memory:
 popfd
 mov eax,0x51
 pop edi
 pop esi
 ret 8
.section .note.GNU-stack,"",@progbits
