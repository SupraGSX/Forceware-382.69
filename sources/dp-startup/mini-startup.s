.intel_syntax noprefix
.code32
.global startup_pair_info, startup_query_init, startup_query_finish
.extern query_pair
# The only callers allowed to set this packet marker are active display mode
# preparation. It is consumed before normal query flags are constructed.
.equ PREPARE,0x44505031
startup_pair_info:
 pushfd
 pushad
 xor ebx,ebx
 cmp dword ptr [esi+0x2c],PREPARE
 jne calculate
 mov dword ptr [esi+0x2c],0
 inc ebx
 test dword ptr [ebp+0x2d00],255
 jnz calculate
 # Verified original dispatch-frame driver context at ESP+11c; pushfd/pushad
 # add 24 hex bytes. Native probe takes (context, output mask, device handle).
 mov eax,[esp+0x140]
 push dword ptr [eax+0x1388]
 push dword ptr [esi+0x30]
 push eax
 call 0x443bf0
calculate:
 push ebx
 push dword ptr [ebp+0x2d34]
 push dword ptr [ebp+0x2d30]
 push dword ptr [ebp+0x2d00]
 call query_pair
 add esp,16
 mov edx,eax
 and edx,255
 shr eax,8
 mov [esi+0x10],edx
 mov [esi+0x0c],eax
 popad
 popfd
 jmp 0x44c749
startup_query_init:
 pushfd
 pushad
 mov ebx,[esi+0x2c]
 push 0x2c
 push 0
 lea eax,[esi+4]
 push eax
 call 0x464040
 add esp,12
 cmp ebx,PREPARE
 jne initialized
 mov [esi+0x2c],ebx
initialized:
 popad
 popfd
 lea edi,[esi+4]
 # Rejoin before the native cleanup of the original three memset arguments.
 sub esp,12
 jmp 0x44c6da
# Consume the private marker on non-DP routes too. Normal DP flags have
# already replaced it; ordinary queries are unchanged.
startup_query_finish:
 pushfd
 cmp dword ptr [esi+0x2c],PREPARE
 jne finished
 mov dword ptr [esi+0x2c],0
finished:
 popfd
 mov edi,[esp+0x130]
 mov eax,[esp+0x10]
 jmp 0x44c99d
.section .note.GNU-stack,"",@progbits
