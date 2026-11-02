.intel_syntax noprefix
.code32
.section .text
.global reset589
reset589:
 pushfd
 push eax
 push edx
 cmp dword ptr [esi+0xc],3
 jne native589
 cmp dword ptr [ebx+0x714],0x130
 jne native589
 mov eax,[ebx+0x710]
 cmp eax,7
 je family589
 cmp eax,8
 jne native589
family589:
 cmp [ebx+0x1674],edi
 jne native589
 mov eax,[ebx+0x16e0]
 test eax,eax
 jz native589
 call 1f
1: pop edx
 sub edx,OFFSET FLAT:1b
 lea edx,[edx+provider391]
 cmp [eax+0x1bc],edx
 jne native589
 /* Native391 skips notification for an already canceled sequence, but
    still releases its queue payload. The original caller already retired
    its callback storage after synchronous cancellation. */
 pop edx
 pop eax
 popfd
 jmp 0x73bb1e
native589:
 pop edx
 pop eax
 popfd
 mov eax,[esi+0x4c]
 mov dword ptr [esi+0xc],3
 jmp 0x73bb08
.section .note.GNU-stack,"",@progbits
