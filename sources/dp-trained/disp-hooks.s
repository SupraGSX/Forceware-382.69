.intel_syntax noprefix
.code32
.global depth_guard, selection_guard, alternate_guard
.extern choose_depth
depth_guard:
 pushfd
 pushad
 # Original ESP+1c points to the pixel clock allocation.
 mov eax,[esp+0x40]
 test eax,eax
 jz depth_reject
 mov eax,[eax]
 mov ecx,[esp+0x68]
 mov edx,[esp+0x6c]
 push edi
 push edx
 push ecx
 push eax
 call choose_depth
 add esp,16
 test eax,eax
 jz depth_reject
 mov [esp],eax # saved EDI
 popad
 popfd
 mov esi,[ebp+0x480]
 jmp 0x492af
depth_reject:
 popad
 popfd
 jmp 0x49885
selection_guard:
 test eax,eax
 jz selection_reject
 push esi
 push 0
 test eax,eax
 jmp 0x492ea
selection_reject:
 jmp 0x49885
alternate_guard:
 test eax,eax
 jz alternate_reject
 mov edx,[esp+0x20]
 jmp 0x4a0f0
alternate_reject:
 # Void escape helper: discard the saved-state allocation, then its own exit.
 # Do not run its old fallback that manufactures a different DP configuration.
 mov esi,[ebx+ebp*4+0x6dc]
 push ebx
 call 0x47210
 test eax,eax
 jz alternate_exit
 mov eax,[esp+0x1c]
 test eax,eax
 jz alternate_exit
 push eax
 call 0x24dd30
alternate_exit:
 jmp 0x4a2f1
.section .note.GNU-stack,"",@progbits
