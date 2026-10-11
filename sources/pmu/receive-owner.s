/* SPDX-License-Identifier: GPL-3.0-only
 * Exact-image patch; all targets are verified by build.py before modification.
 * Queue stride 0x68; constructor +854828..+85482d zeroes all 0x68 bytes.
 * In this image +65/+66 are unused tail padding, adjacent to native open+64.
 * +65: nonblocking receive owner (0 or 1); +66: deferred-service request.
 * No lock is held over the upper message callbacks or response waits.
 * x86 locked byte operations provide admission/release ordering. There is no
 * spin or IRQL change, so an interrupt cannot deadlock behind its own CPU.
 */
.intel_syntax noprefix
.section .text
.global rx_claim,rx_empty,rx_return,rx_irq_recheck,rx_stats
rx_claim:
    push edx
    xor eax,eax
    mov dl,1
    lock cmpxchg byte ptr [edi+0x65],dl
    pop edx
    jnz rx_busy
    push eax
    call 1f
1:  pop eax
    lock inc dword ptr [eax+rx_stats+8-1b]
    pop eax
    mov eax,[edi+4]
    push edi
    push esi
    jmp 0x86e068
rx_busy:
    /* Publish pending before returning. Native +5b6909 acknowledges IRQ first;
       the post-ack hook below consumes pending and requests another IRQ pass. */
    mov al,1
    xchg byte ptr [edi+0x66],al
    call 2f
2:  pop eax
    lock inc dword ptr [eax+rx_stats+12-2b]
    mov eax,0x1a
    /* Deliberately bypass owner-release: this invocation never acquired it. */
    pop edi
    pop esi
    pop ebp
    pop ebx
    pop ecx
    ret 16
rx_empty:
    push eax
    xor eax,eax
    xchg byte ptr [edi+0x65],al
    call 3f
3:  pop eax
    lock inc dword ptr [eax+rx_stats+16-3b]
    pop eax
    pop edi
    pop esi
    pop ebp
    mov eax,0x55
    jmp 0x86e077
rx_return:
    push eax
    xor eax,eax
    xchg byte ptr [edi+0x65],al
    call 4f
4:  pop eax
    lock inc dword ptr [eax+rx_stats+20-4b]
    pop eax
    pop edi
    pop esi
    pop ebp
    pop ebx
    pop ecx
    ret 16
rx_irq_recheck:
    /* Replay original queue-empty callback. It pops its three arguments. */
    call edx
    push ecx
    push edx
    /* Original local +14 is queue configuration, +28 is array base.
       The original caller and its callback explicitly target queue index 4. */
    mov edx,[esp+0x1c]
    mov edx,[edx+0x28]
    xor ecx,ecx
    xchg byte ptr [edx+0x1a0+0x66],cl
    test cl,cl
    jz 5f
    xor eax,eax
    push eax
    call 6f
6:  pop eax
    lock inc dword ptr [eax+rx_stats+24-6b]
    pop eax
5:  pop edx
    pop ecx
    test al,al
    jnz 0x5c6966
    jmp 0x5c6952
.balign 16
rx_stats:
    .ascii "FWRX130\0"
    .long 0,0,0,0,0,0
.section .note.GNU-stack,"",@progbits
