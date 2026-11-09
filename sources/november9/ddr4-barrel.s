 .intel_syntax noprefix
.code32
.section .text
.global barrel_hook
barrel_hook:
 pushfd
 pushad
 cmp dword ptr [ebp+0x710],8
 jne barrel_done
 cmp dword ptr [ebp+0x714],0x130
 jne barrel_done
 cmp dword ptr [ebp+0x1610],esi
 jne barrel_done
 cmp dword ptr [esi+0xca4],12
 jne barrel_done
 /* Only the captured single-partition contract is backported here. */
 cmp dword ptr [esi+0x2b48],1
 jne barrel_done
 /* Original local at ESP+14 before pushfd/pushad: training_enabled. */
 test dword ptr [esp+0x38],0x80000
 jnz barrel_done
 mov edi,[edi+0x288]
 push 1
 push ebx
 call 0x531780
 .macro emit off
 push edi
 push \off
 push 0
 push 0
 push esi
 push ebp
 call dword ptr [esi+0x65c]
 push eax
 push ebx
 call 0x5318a0
 .endm
 emit 0xc20
 emit 0xc2c
 emit 0xc38
 emit 0xc44
 emit 0xc50
 emit 0xc5c
 emit 0xc68
 emit 0xc74
 push 1
 push ebx
 call 0x531780
barrel_done:
 popad
 popfd
 cmp byte ptr [esp+0x24],0
 jmp 0x654335
.section .note.GNU-stack,"",@progbits
