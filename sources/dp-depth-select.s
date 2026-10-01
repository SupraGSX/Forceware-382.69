.intel_syntax noprefix
.code32
.global _start
_start:
 pushfd
 push eax
 push ecx
 push edx
 push ebx
 cmp edi,3
 jne done
 mov ecx,dword ptr [esp+0x58]
 cmp ecx,6
 je rate_ok
 cmp ecx,10
 je rate_ok
 cmp ecx,20
 je rate_ok
 cmp ecx,30
 jne done
rate_ok:
 mov edx,dword ptr [esp+0x5c]
 cmp edx,1
 je lanes_ok
 cmp edx,2
 je lanes_ok
 cmp edx,4
 jne done
lanes_ok:
 imul ecx,edx
 imul ecx,ecx,21600
 mov eax,dword ptr [esp+0x30]
 test eax,eax
 jz done
 mov ebx,dword ptr [eax]
 mov eax,0x51eb851f
 mul ebx
 shr edx,6
 add edx,ebx
 jc depth8
 imul edx,edx,30
 jo depth8
 cmp edx,ecx
 jbe done
depth8:
 mov edi,2
done:
 pop ebx
 pop edx
 pop ecx
 pop eax
 popfd
 mov esi,dword ptr [ebp+0x480]
 jmp 0x492af
