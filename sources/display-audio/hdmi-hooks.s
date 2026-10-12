.intel_syntax noprefix
.code32
.section .early,"ax",@progbits
.global early_refresh
early_refresh:
 pushfd
 pushad
 push ebx
 push ebp
 call bridge
 add esp,8
 popad
 popfd
 push ebx
 lea eax,[esp+0xb4]
 jmp early_resume
.section .refresh,"ax",@progbits
.global refresh
refresh:
 pushfd
 pushad
 mov eax,[esp+0x134]
 push ebx
 push eax
 call bridge
 add esp,8
.global refresh_result
refresh_result:
 popad
 popfd
 and dword ptr [ebx+0x20],0xfffffffb
 mov edi,[esp+0x114]
 jmp refresh_resume
.section .receiver,"ax",@progbits
.global receiver
receiver:
 pushfd
 pushad
 mov eax,[esp+0x44]
 push dword ptr [edi+8]
 push esi
 push ebx
 push eax
 call applyClock
 add esp,16
.global receiver_result
receiver_result:
 popad
 popfd
 mov ecx,[edi+4]
 lea eax,[esp+0x10]
 jmp receiver_resume
.section .note.GNU-stack,"",@progbits
