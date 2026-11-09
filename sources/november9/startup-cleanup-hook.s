.intel_syntax noprefix
.code32
.section .text
.global failed_start844
.extern cleanup844
failed_start844:
 pushfd
 pushad
 cld
 mov ebx,esp
 call 1f
1:pop edx
 sub edx,OFFSET FLAT:1b
 # Only the stock first-start wrapper caller, not another invocation.
 lea eax,[edx+0x474f34]
 cmp dword ptr [ebx+52],eax
 jne .Lreplay
 lea eax,[edx+0x104fd3d]
 push eax
 lea eax,[edx+0x73f010]
 push eax
 lea eax,[edx+0xf0d3a3]
 push eax
 lea eax,[edx+0xf0b550]
 push eax
 push dword ptr [ebx+60]
 push dword ptr [ebx]
 push dword ptr [ebx+4]
 call cleanup844
.Lreplay:
 popad
 popfd
 # Replay the native terminal epilogue after all native status selection/logging.
 mov eax,edi
 pop edi
 pop esi
 pop ebx
 jmp 0x4ac216
.section .note.GNU-stack,"",@progbits
