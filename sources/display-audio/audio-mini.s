.intel_syntax noprefix
.code32
.section .text
.global query_entry, parsed_entry, refresh_summary_entry
query_entry:
 cmp dword ptr [esp+8],0x782e
 jne original_query
 cmp dword ptr [esp+12],8
 jne original_query
 mov eax,[esp+16]
 test eax,eax
 jz original_query
 cmp dword ptr [eax],0x11
 jne original_query
 jmp audioGate
original_query:
 sub esp,0x108
 jmp query_resume
parsed_entry:
 mov eax,[esp+0x12c]
 jmp parsed_common
refresh_summary_entry:
 mov eax,ebp
 push ebp
 mov ebp,esp
 push dword ptr [ebp+16]
 push dword ptr [ebp+12]
 push dword ptr [ebp+8]
 push eax
 call refreshSummary
 pop ebp
 ret 12
parsed_common:
 push ebp
 mov ebp,esp
 push dword ptr [ebp+16]
 push dword ptr [ebp+12]
 push dword ptr [ebp+8]
 push eax
 call parsedAudio
 pop ebp
 ret 12
.section .note.GNU-stack,"",@progbits

.section .text
.global dp_audio_presence_entry
dp_audio_presence_entry:
 pushad
 mov eax,[esp+0x13c]
 push ebp
 push eax
 call sinkAudio
 test eax,eax
 popad
 jmp dp_audio_presence_resume
