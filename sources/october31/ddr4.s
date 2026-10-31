.intel_syntax noprefix
.code32
.section .text

/* Only the current adapter's GP108 DDR4 path changes. */
.global timing_entry
timing_entry:
    pushfd
    push eax
    mov eax,[esp+12]
    cmp dword ptr [eax+0x710],8
    jne timing_other
    cmp dword ptr [eax+0x714],0x130
    jne timing_other
    mov eax,[esp+16]
    cmp dword ptr [eax+0xca4],12
    jne timing_other
    pop eax
    popfd
    jmp timing_ddr4
timing_other:
    pop eax
    popfd
.global timing_original
timing_original:
    push ebx
    mov ebx,[esp+12]
    jmp 0x645f45

/* Keep the native partition selection, errors and seven-bit VREF encoding.
 * XP retains both halves of the ROM byte at decoded-row offsets 41/42.
 * No new object field or later-driver layout is introduced. */
.global timing_ddr4
timing_ddr4:
    push ebp
    mov ebp,esp
    push ebx
    push esi
    push edi
    sub esp,4
    mov esi,[ebp+12]
    mov edi,[ebp+16]
    mov eax,[esi+0x2b48]
    mov edx,[esi+0x2b4c]
    cmp eax,1
    je timing_default
    mov ecx,[edi+0x1b8]
    cmp ecx,eax
    jb timing_group
timing_default:
    mov ecx,edx
timing_group:
    push ecx
    push dword ptr [ebp+20]
    push esi
    call 0x7b0340
    test eax,eax
    jz timing_missing
    movzx edx,byte ptr [eax+0x42]
    shl edx,4
    movzx ecx,byte ptr [eax+0x41]
    or edx,ecx
    and edx,0x7f
    mov [ebp-16],edx
    push dword ptr [ebp+24]
    push dword ptr [ebp+20]
    push edi
    push esi
    push dword ptr [ebp+8]
    call timing_original
    test eax,eax
    jnz timing_done
    test dword ptr [esi+0xcac],0x200000
    jz timing_done
    mov edx,[edi+0x180]
    and edx,0xffffff80
    or edx,[ebp-16]
    mov [edi+0x180],edx
    jmp timing_done
timing_missing:
    mov eax,0x4a
timing_done:
    add esp,4
    pop edi
    pop esi
    pop ebx
    pop ebp
    ret 20

/* Hook the SDDR3/4 sequence only. The GDDR5 sequence is untouched.
 * At this boundary ESI=GPU, EBP=FB, EDI=script, stack+24=clock context,
 * stack+18=current PWRD and stack+28=the native calibration decision. */
.global calibration_entry
calibration_entry:
    pushfd
    pushad
    cmp dword ptr [esi+0x710],8
    jne calibration_other
    cmp dword ptr [esi+0x714],0x130
    jne calibration_other
    cmp dword ptr [ebp+0xca4],12
    jne calibration_other
    lea ebx,[esp+36]
    mov eax,[ebx+0x24]
    /* fbTiming begins at context+1d0; flags3 is timing+94, hence +264. */
    mov eax,[eax+0x264]
    push dword ptr [ebx+0x28]
    lea edx,[ebx+0x18]
    push edx
    push eax
    push edi
    push ebp
    push esi
    call calibration_ddr4
    popad
    popfd
    jmp 0x6a8c7b
calibration_other:
    popad
    popfd
    cmp dword ptr [esp+0x28],0
    jmp 0x6a8bf0

/* Complete the ROM producer for periodic DDR4 calibration. Entry is after
 * successful version-11 decoding, with EAX=Flags5 and EBP=decoded row.
 * Keep error exits and shorter, zero-filled strap formats unchanged. */
.global periodic_decode
periodic_decode:
    pushfd
    pushad
    mov ecx,[esp+36+0x64]
    cmp dword ptr [ecx+0x710],8
    jne periodic_done
    cmp dword ptr [ecx+0x714],0x130
    jne periodic_done
    mov ecx,[ecx+0x1610]
    test ecx,ecx
    jz periodic_done
    cmp dword ptr [ecx+0xca4],12
    jne periodic_done
    test al,0x80
    jz periodic_done
    or dword ptr [ebp+0x14],4
periodic_done:
    popad
    popfd
    mov ecx,eax
    shr ecx,4
    jmp 0x6fcc0a

/* stdcall(GPU,FB,script,flags3,PWRD*,enable); exact native391 emission order.
 * Register mapping, hardware access and script insertion use XP callbacks. */
.global calibration_ddr4
calibration_ddr4:
    push ebp
    mov ebp,esp
    push ebx
    push esi
    push edi
    sub esp,8
    mov esi,[ebp+8]
    mov ebx,[ebp+12]
    mov edi,[ebp+16]
    test dword ptr [ebp+20],4
    jz calib_check_enable
    cmp byte ptr [ebp+28],0
    jne calib_check_enable
    push 1
    push 0
    call 0x4877b0
calib_check_enable:
    cmp byte ptr [ebp+28],0
    je calib_disable
    mov eax,0x670
    call read_register
    mov [ebp-16],eax
    mov eax,0x60c
    call read_register
    mov [ebp-20],eax
    mov ecx,[ebp+24]
    mov edx,[ecx]
    mov eax,edx
    and edx,0xfcffffff
    mov [ecx],edx
    cmp eax,edx
    je calib_start
    mov eax,0x824
    call emit_register
calib_start:
    mov edx,12
    test dword ptr [ebp+20],4
    jz calib_start_write
    mov edx,8
calib_start_write:
    mov eax,0x1f50
    call emit_register
    mov edx,[ebp-16]
    and edx,0xf0ffffff
    or edx,0x80000000
    mov eax,0x670
    call emit_register
    push 10
    push edi
    call 0x5317a0
    mov edx,[ebp-16]
    and edx,0x70ffffff
    mov eax,0x670
    call emit_register
    test dword ptr [ebp+20],4
    jz calib_spare
    mov eax,0x1f50
    mov edx,10
    call emit_register
calib_spare:
    mov edx,[ebp-20]
    or edx,2
    mov eax,0x60c
    call emit_register
    jmp calib_done
calib_disable:
    mov eax,0x1f50
    mov edx,12
    call emit_register
calib_done:
    add esp,8
    pop edi
    pop esi
    pop ebx
    pop ebp
    ret 24

read_register:
    push eax
    push 0
    push 0
    push ebx
    push esi
    call dword ptr [ebx+0x65c]
    push eax
    push 0
    push 0
    push esi
    call dword ptr [esi+0x1dc]
    ret
emit_register:
    push edx
    push eax
    push 0
    push 0
    push ebx
    push esi
    call dword ptr [ebx+0x65c]
    push eax
    push edi
    call 0x5318a0
    ret
.section .note.GNU-stack,"",@progbits
