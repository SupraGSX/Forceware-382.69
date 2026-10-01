.intel_syntax noprefix
.code32
.global _start
_start:
 pushad
 sub esp,16
 test byte ptr [ebp+14],0x80
 jz done
 mov eax,esp
 push 1
 push 15
 push 0x2200
 push 16
 push eax
 push edi
 push esi
 call 0x442930
 test eax,eax
 jnz done
 mov al,byte ptr [ebp]
 cmp byte ptr [esp],al
 jb done
 mov al,byte ptr [esp+1]
 cmp al,6
 je rate_ok
 cmp al,10
 je rate_ok
 cmp al,20
 je rate_ok
 cmp al,30
 jne done
rate_ok:
 mov al,byte ptr [esp+2]
 and al,31
 cmp al,1
 je lanes_ok
 cmp al,2
 je lanes_ok
 cmp al,4
 jne done
lanes_ok:
 mov eax,dword ptr [esp]
 mov dword ptr [ebp],eax
 mov eax,dword ptr [esp+4]
 mov dword ptr [ebp+4],eax
 mov eax,dword ptr [esp+8]
 mov dword ptr [ebp+8],eax
 mov ax,word ptr [esp+12]
 mov word ptr [ebp+12],ax
 mov al,byte ptr [esp+14]
 mov byte ptr [ebp+14],al
done:
 add esp,16
 popad
 jmp 0x10630
