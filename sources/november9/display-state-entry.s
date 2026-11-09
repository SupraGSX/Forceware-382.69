.intel_syntax noprefix
.section .text
.global entry_inline634,entry_handoff634,marker634,native_copy634
.extern inline634,handoff634
entry_inline634:
 push dword ptr [esp+12]
 push dword ptr [esp+12]
 push dword ptr [esp+12]
 push edi
 push esi
 push ebp
 call inline634
 ret 12
entry_handoff634:
 push dword ptr [esp+12]
 push dword ptr [esp+12]
 push dword ptr [esp+12]
 push edi
 push esi
 push ebp
 call handoff634
 ret 12
marker634:
 call 1f
1: pop eax
 .byte 0x2d
 .long 1b-0xf0d3a3
 ret
native_copy634:
 jmp 0x470d10

.section .note.GNU-stack,"",@progbits
