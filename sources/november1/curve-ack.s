.intel_syntax noprefix
.code32
.section .text
.global curve_ack591
curve_ack591:
 pushfd
 push eax
 test esi,esi
 jnz 1f
 mov eax,[ebp+8]
 test eax,eax
 jz 1f
 cmp dword ptr [eax+0x714],0x130
 jne 1f
 cmp dword ptr [eax+0x710],7
 je 2f
 cmp dword ptr [eax+0x710],8
 jne 1f
2:
 /* The original callback773160 requires legacy type0 and ACK byte1.
    ESI is the actual validated firmware/transport status, never forced. */
 mov byte ptr [ebp-0xb],1
1:
 pop eax
 popfd
 lea edx,[ebp-0x10]
 push esi
 push dword ptr [ebp+0x14]
 jmp 0x1050070
.section .note.GNU-stack,"",@progbits
