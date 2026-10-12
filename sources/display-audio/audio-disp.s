.intel_syntax noprefix
.code32
.section .text
.global validate_entry, failure_entry
validate_entry:
 pushfd
 pushad
 lea eax,[esp+36]
 push ebp
 push eax
 call validateEld
 add esp,8
 popad
 popfd
 mov edx,[esp+0xac]
 jmp validate_resume
failure_entry:
 pushfd
 pushad
 lea eax,[esp+36]
 push ebp
 push eax
 call failedEld
 add esp,8
 popad
 popfd
 mov dword ptr [esp+0x1c],1
 jmp failure_resume
.section .note.GNU-stack,"",@progbits
