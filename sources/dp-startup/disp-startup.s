.intel_syntax noprefix
.code32
.global prepare_query
# Preserve the stock 47DD0 register/stack ABI: EDI output mask, ESI packet,
# one stdcall PDEV argument. Only active mode callers use this entry.
prepare_query:
 push ebx
 mov ebx,[esp+8]
 push ebx
 call probe_query
 test eax,eax
 jnz preparation_done
 cmp dword ptr [esi+0x0c],0
 je bootstrap
 cmp dword ptr [esi+0x10],0
 jne preparation_done
bootstrap:
 # Native probing refuses an already-owned active output. Use the existing
 # mode-configuration helper's quiesce/commit lifecycle, never force success.
 # Auto/default arguments let its ordinary query choose initial candidates.
 # Even if the initial requested maximum fails, its real automatic probe can
 # populate lower successful pairs; the final query decides whether to proceed.
 push 0
 push 0 # do not permit the native matching-settings early return
 push -1
 push -1
 push -1
 push -1
 push 0
 push 0
 push edi
 mov eax,ebx
 call 0x481a0
 push ebx
 call probe_query
preparation_done:
 pop ebx
 ret 4
probe_query:
 sub esp,12
 push ebx
 mov ebx,[esp+0x14]
 test ebx,ebx
 jz invalid
 test edi,0xffffff00
 jz invalid
 test edi,edi
 jz invalid
 lea eax,[edi-1]
 test edi,eax
 jnz invalid
 push 0x34
 push 0
 push esi
 call 0x29bed0
 add esp,12
 lea ecx,[esp+0x14]
 push ecx
 push 0x34
 push esi
 push 0x0c
 lea edx,[esp+0x14]
 push edx
 mov dword ptr [esi],0x12
 mov [esi+0x30],edi
 mov dword ptr [esi+0x2c],0x44505031
 mov eax,[ebx+8]
 push 0x232ee0
 push eax
 mov dword ptr [esp+0x20],0x782e
 mov dword ptr [esp+0x24],0x34
 mov [esp+0x28],esi
 call 0x24dd24
 neg eax
 sbb eax,eax
 neg eax
 pop ebx
 add esp,12
 ret 4
invalid:
 mov eax,1
 pop ebx
 add esp,12
 ret 4
.section .note.GNU-stack,"",@progbits
