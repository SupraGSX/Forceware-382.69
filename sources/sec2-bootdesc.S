.intel_syntax noprefix
.code32
.text
.global sec2_bootdesc_copy
.extern original_copy
# Hook only the final WPR boot-data copy at XP368 VA 7271E3.
# Incoming EDI is the observed per-Falcon WPR node. Original function is stdcall(3).
sec2_bootdesc_copy:
 cmp dword ptr [edi+4],7
 jne original_copy
 cmp dword ptr [esp+12],0x38
 jne original_copy
 cmp dword ptr [edi+0xf4],0x100
 jne original_copy
 mov eax,[edi+0x168]
 test eax,eax
 jz original_copy
 cmp dword ptr [eax+0xc],0x014a7c8c
 jne original_copy
 cmp dword ptr [eax+0x5c],0xfd00
 jne original_copy
 push ebp
 mov ebp,esp
 push ebx
 push esi
 push edi
 sub esp,0x54
 mov ebx,esp
 mov esi,[ebp+12]
 mov edi,ebx
 xor eax,eax
 mov ecx,21
 rep stosd
 mov eax,[esi+4]
 mov [ebx+0x20],eax
 mov eax,[esi+8]
 mov [ebx+0x24],eax
 mov eax,[esi+12]
 mov [ebx+0x28],eax
 mov edi,[ebp-12]
 mov edi,[edi+0x168]
 mov eax,[edi+0x74]
 mov [ebx+0x2c],eax
 mov eax,[esi+0x14]
 mov [ebx+0x30],eax
 mov eax,[esi+0x18]
 mov [ebx+0x3c],eax
 mov eax,[esi+0x1c]
 mov [ebx+0x40],eax
 mov eax,[esi+0x20]
 mov [ebx+0x44],eax
 mov eax,[esi+0x24]
 mov [ebx+0x48],eax
 mov eax,[esi+0x30]
 mov [ebx+0x4c],eax
 mov eax,[esi+0x34]
 mov [ebx+0x50],eax
 push 0x54
 push ebx
 push dword ptr [ebp+8]
 call original_copy
 add esp,0x54
 pop edi
 pop esi
 pop ebx
 pop ebp
 ret 12
