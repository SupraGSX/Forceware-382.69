.intel_syntax noprefix
.code32
.section .text
.global create_overscan, route_panel, digital_display, page_info
# Create a second, independent instance of the existing XP page. Never alter
# a live scaling instance, the GPU, display identity or EDID.
create_overscan:
 push ebp
 mov ebp,esp
 sub esp,8
 push ebx
 push esi
 cmp DWORD PTR [ebp+8],0
 jne aggregated
 push DWORD PTR [ebp+16]
 push DWORD PTR [ebp+12]
 push DWORD PTR [ebp+8]
 call 0x1005c6a9
 mov [ebp-4],eax
 test eax,eax
 js done
 mov ebx,[ebp+16]
 mov ebx,[ebx]
 test ebx,ebx
 jz done
 mov DWORD PTR [ebp-8],0
 lea eax,[ebp-8]
 push eax
 push OFFSET FLAT:iid_unknown
 push ebx
 mov eax,[ebx]
 call DWORD PTR [eax]
 test eax,eax
 js failed_creation
 mov esi,[ebp-8]
 cmp DWORD PTR [esi],0x1024cd8c
 jne mark_failed
 mov DWORD PTR [esi],OFFSET FLAT:overscan_vtable
release:
 push esi
 mov eax,[esi]
 call DWORD PTR [eax+8]
done:
 mov eax,[ebp-4]
 pop esi
 pop ebx
 mov esp,ebp
 pop ebp
 ret 12
aggregated:
 mov eax,[ebp+16]
 test eax,eax
 jz aggregate_error
 mov DWORD PTR [eax],0
aggregate_error:
 mov DWORD PTR [ebp-4],0x80040110
 jmp done
mark_failed:
 mov DWORD PTR [ebp-4],0x8000ffff
 push esi
 mov eax,[esi]
 call DWORD PTR [eax+8]
 jmp release_created
failed_creation:
 mov [ebp-4],eax
release_created:
 push ebx
 mov eax,[ebx]
 call DWORD PTR [eax+8]
 mov edx,[ebp+16]
 mov DWORD PTR [edx],0
 jmp done
# Share instance-specific selection across show/hide, commands, notifications
# and display validation. ESI is the legacy instance at all six call sites.
route_panel:
 cmp DWORD PTR [esi],OFFSET FLAT:overscan_vtable
 jne native_route
 cmp BYTE PTR [esi+0x2e4],0
 je unavailable
 mov eax,3
 ret
unavailable:
 mov eax,4
 ret
native_route:
 push DWORD PTR [esp+4]
 call digital_display
 add esp,4
 test al,al
 jz original_route
 mov eax,1
 ret
original_route:
 jmp 0x100569c3
# A digital connection is enough to expose the page. Individual radio choices
# are still enumerated and validated by native setting 0x60, never fabricated.
digital_display:
 push ebp
 mov ebp,esp
 sub esp,20
 push ebx
 mov ebx,[ebp+8]
 test ebx,ebx
 jz not_digital
 cmp DWORD PTR [ebx+4],3
 ja not_digital
 mov DWORD PTR [ebp-20],0
 mov DWORD PTR [ebp-16],0
 mov DWORD PTR [ebp-12],0
 mov DWORD PTR [ebp-8],0
 mov DWORD PTR [ebp-4],0
 push 20
 lea eax,[ebp-20]
 push eax
 push 2
 push ebx
 push 0
 call 0x100d621f
 add esp,20
 test eax,eax
 jnz not_digital
 mov ecx,[ebx+4]
 mov eax,[ebp-16+ecx*4]
 test eax,0x10
 jnz not_digital
 test eax,0xc0
 setnz al
 movzx eax,al
 jmp digital_done
not_digital:
 xor eax,eax
digital_done:
 pop ebx
 mov esp,ebp
 pop ebp
 ret
# IPropertyPage::GetPageInfo uses COM-owned strings. Preserve native results,
# allocation ownership and failure behavior while separating task captions.
# This native client uses HelpFile as the short navigation caption whenever
# HelpContext is nonzero (client 0041C130). DocString remains native prose.
page_info:
 push ebp
 mov ebp,esp
 sub esp,8
 push ebx
 push esi
 push edi
 push DWORD PTR [ebp+12]
 push DWORD PTR [ebp+8]
 call 0x1005c331
 mov [ebp-4],eax
 test eax,eax
 js info_done
 mov ebx,[ebp+12]
 test ebx,ebx
 jz info_done
 mov eax,[ebp+8]
 cmp DWORD PTR [eax],OFFSET FLAT:overscan_vtable
 jne info_caption_ready
 cmp BYTE PTR [eax+0x2e4],0
 jne info_caption_ready
 # Native overscan child unavailable: do not expose an empty overscan page.
 # Free the successfully returned native COM strings before declining it.
 mov esi,4
info_free:
 push DWORD PTR [ebx+esi]
 call DWORD PTR [0x10249768]
 mov DWORD PTR [ebx+esi],0
 cmp esi,20
 je info_unavailable
 cmp esi,4
 jne info_last_free
 mov esi,16
 jmp info_free
info_last_free:
 mov esi,20
 jmp info_free
info_unavailable:
 mov DWORD PTR [ebp-4],0x80004027
 jmp info_done
info_caption_ready:
 mov DWORD PTR [ebp-8],4
info_label:
 mov esi,OFFSET FLAT:scaling_name
 mov ecx,46
 mov eax,[ebp+8]
 cmp DWORD PTR [eax],OFFSET FLAT:overscan_vtable
 jne info_allocate
 mov esi,OFFSET FLAT:overscan_name
 mov ecx,32
info_allocate:
 push ecx
 push ecx
 call DWORD PTR [0x10249760]
 pop ecx
 test eax,eax
 jz info_next
 mov edi,eax
 push eax
 rep movsb
 mov edx,[ebp-8]
 push DWORD PTR [ebx+edx]
 call DWORD PTR [0x10249768]
 pop eax
 mov edx,[ebp-8]
 mov [ebx+edx],eax
info_next:
 cmp DWORD PTR [ebp-8],4
 jne info_done
 mov DWORD PTR [ebp-8],20
 jmp info_label
info_done:
 mov eax,[ebp-4]
 pop edi
 pop esi
 pop ebx
 mov esp,ebp
 pop ebp
 ret 8
.balign 2
scaling_name:
.short 65,100,106,117,115,116,32,100,101,115,107,116,111,112,32,115,99,97,108,105,110,103,0
.balign 2
overscan_name:
.short 65,100,106,117,115,116,32,111,118,101,114,115,99,97,110,0
.balign 4
iid_unknown:
.long 0,0,0xC0,0x46000000
# The build script replaces this placeholder with the exact native vtable,
# including its original RTTI prefix and native Apply/confirmation methods.
.balign 4
overscan_rtti:
.long 0
overscan_vtable:
.space 72

