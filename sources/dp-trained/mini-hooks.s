.intel_syntax noprefix
.code32
.global pair_info
.extern best_pair
pair_info:
 pushfd
 pushad
 push dword ptr [ebp+0x2d34]
 push dword ptr [ebp+0x2d30]
 push dword ptr [ebp+0x2d00]
 call best_pair
 add esp,12
 mov edx,eax
 and edx,255
 shr eax,8
 mov [esi+0x10],edx
 mov [esi+0x0c],eax
 popad
 popfd
 jmp 0x44c749
