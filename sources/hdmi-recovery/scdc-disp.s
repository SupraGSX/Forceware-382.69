.intel_syntax noprefix
.code32
.section .text
.global begin_hook,end_hook,accumulate
/* Both hooks are in 48DD0, with EBX=physical mode and EBP=PDEV.
 * EAX/ECX are the native 3A620 RM handle registers, not conventional cdecl.
 */
is_high_hdmi:
 xor eax,eax
 test ebx,ebx
 jz 1f
 cmp dword ptr [ebx+0x34],34000
 jbe 1f
 mov eax,[ebx]
 mov ecx,ebp
 call 0x47990
 and eax,3
 cmp eax,3
 sete al
 movzx eax,al
1: ret
control:
 push edx
 push dword ptr [ebx]
 push dword ptr [ebp+0xe4]
 mov edx,esp
 push 12
 push edx
 push 0x730293
 push dword ptr [ebp+8]
 mov eax,[ebp+0x70]
 mov ecx,[ebp+0x98]
 call 0x3a620
 add esp,16
 test eax,eax
 jne 1f
 mov eax,[esp+8]
 cmp eax,1
 sete al
 movzx eax,al
 jmp 2f
1: xor eax,eax
2: add esp,12
 ret
begin_hook:
 pushad
 call is_high_hdmi
 test eax,eax
 jz begin_ok
 mov edx,0xd8434401
 call control
 test eax,eax
 jz begin_fail
 or byte ptr [esp+0x33],0x80 /* mode-local armed bit, consumed at cleanup */
begin_ok:
 popad
 test byte ptr [ebp+0xfc],0xf0
 jmp 0x49688
begin_fail:
 popad
 jmp 0x49885
end_hook:
 test byte ptr [esp+0x13],0x80
 jz end_original
 and byte ptr [esp+0x13],0x7f
 pushad
 mov edx,0xd8434402
 call control
 test eax,eax
 jnz end_ok
 mov byte ptr [esp+0x33],0 /* original +13 flag */
end_ok:
 popad
end_original:
 test ebx,ebx
 jz 0x4989c
 push ebx
 jmp 0x49897
accumulate:
 test eax,eax
 jnz good
 mov byte ptr [esp+0x13],0
good:
 add dword ptr [esp+0x14],4
 jmp 0x49c3a
.section .note.GNU-stack,"",@progbits
