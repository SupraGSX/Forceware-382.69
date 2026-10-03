.intel_syntax noprefix
.code32
.section .text
.global command_hook,write_hook,state_address
command_hook:
 cmp dword ptr [edi+8],0xd8434401
 je private_command
 cmp dword ptr [edi+8],0xd8434402
 je private_command
 test byte ptr [edi+8],1
 jz 0x79c51a
 jmp 0x79c508
private_command:
 pushad
 push dword ptr [edi+8]
 push ebx
 push dword ptr [esp+0x48] /* original [esp+20] GPU after pushad + 8 */
 call transaction
 add esp,12
 mov [edi+8],eax
 popad
 mov dword ptr [esp+0x14],0
 jmp 0x79c5cf
write_hook:
 pushad
 push dword ptr [esp+0x58] /* original +38 config */
 push ebp
 push dword ptr [esp+0x5c] /* original +34 common, pushad+8 */
 push esi
 call setup_write
 add esp,16
 mov [esp+28],eax
 popad
 jmp 0x6e3192
state_address:
 call 1f
1: pop eax
 add eax,state-1b
 ret
.section .data
.balign 4
state: .zero 1032
.section .note.GNU-stack,"",@progbits
