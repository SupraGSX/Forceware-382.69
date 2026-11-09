.intel_syntax noprefix
.code32
.global bus_legacy_ack_status
bus_legacy_ack_status:
 pushfd
 test edi,edi
 setz byte ptr [ebp-0x155]
 popfd
 mov eax,[ebp+0x2c]
 sub esp,0x0c
 jmp 0x10556bf
