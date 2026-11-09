.intel_syntax noprefix
.code32
.section .text
.global clock_drive_hook
clock_drive_hook:
 pushfd
 pushad
 cmp dword ptr [esi+0x710],8
 jne drive_done
 cmp dword ptr [esi+0x714],0x130
 jne drive_done
 cmp dword ptr [esi+0x1610],ebp
 jne drive_done
 cmp dword ptr [ebp+0xca4],12
 jne drive_done
 push dword ptr [ebx+0x260]
 push edi
 push ebp
 push esi
 call drive_mode
 drive_done:
 popad
 popfd
 cmp byte ptr [ebp+0x779],0
 jmp 0x6a8b6d
.global quse_hook
quse_hook:
 pushfd
 push eax
 cmp dword ptr [esi+0x710],8
 jne quse_other
 cmp dword ptr [esi+0x714],0x130
 jne quse_other
 cmp dword ptr [esi+0x1610],ebp
 jne quse_other
 cmp dword ptr [ebp+0xca4],12
 jne quse_other
 pop eax
 popfd
 jmp 0x6a8b90
 quse_other:
 pop eax
 popfd
 cmp byte ptr [ebp+0x787],0
 jmp 0x6a8b8e
/* stdcall(GPU,FB,script,flags2); all values derive from selected timing
 * and actual readbacks. Preserve native register bits and write ordering. */
.global drive_mode
drive_mode:
 push ebp
 mov ebp,esp
 push ebx
 push esi
 push edi
 sub esp,12
 mov esi,[ebp+8]
 mov edi,[ebp+16]
 mov ebx,[ebp+20]
 mov eax,0x9a1f38
 call readreg
 and eax,0xfffeffff
 test ebx,0x20000000
 jnz wck_set
 or eax,0x10000
wck_set:
 mov [ebp-16],eax
 mov eax,0x9a1f34
 call readreg
 and eax,0xfffeffff
 test ebx,0x10000000
 jnz ck_set
 or eax,0x10000
ck_set:
 mov [ebp-20],eax
 mov eax,0x9a0d34
 call readreg
 and eax,0x77ffffff
 mov edx,ebx
 and edx,0x10000000
 shr edx,1
 or eax,edx
 mov edx,ebx
 and edx,0x20000000
 shl edx,2
 or eax,edx
 mov [ebp-24],eax
 push dword ptr [ebp-16]
 push 0x9a1f38
 push edi
 call 0x5318a0
 push dword ptr [ebp-20]
 push 0x9a1f34
 push edi
 call 0x5318a0
 push dword ptr [ebp-24]
 push 0x9a0d34
 push edi
 call 0x5318a0
 add esp,12
 pop edi
 pop esi
 pop ebx
 pop ebp
 ret 16
readreg:
 push eax
 push 0
 push 0
 push esi
 call dword ptr [esi+0x1dc]
 ret
.section .note.GNU-stack,"",@progbits
