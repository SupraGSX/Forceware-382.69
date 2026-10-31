/* Native XP RM semaphore ownership for queued Pascal VFE work.
 * Select using the current adapter; preserve the original worker on other GPUs.
 */
.intel_syntax noprefix
.code32
.section .text
.global choose_worker, vfe_locked_worker
choose_worker:
 push 0
 pushfd
 pushad
 call 1f
1: pop eax
 sub eax,OFFSET FLAT:1b-0x10000
 lea edx,[eax+0x762e30]
 cmp dword ptr [ecx+0x714],0x130
 jne 2f
 mov ebx,[ecx+0x710]
 cmp ebx,2
 je 3f
 cmp ebx,4
 je 3f
 cmp ebx,6
 je 3f
 cmp ebx,7
 je 3f
 cmp ebx,8
 jne 2f
3: lea edx,[eax+vfe_locked_worker-0x10000]
2: mov [esp+36],edx
 popad
 popfd
 jmp 0x772eee

vfe_locked_worker:
 push ebx
 push ebp
 push esi
 push edi
 call 4f
4: pop ebp
 sub ebp,OFFSET FLAT:4b-0x10000
 mov ebp,[ebp+0xc59954]
 mov eax,[ebp+0x2064]
 push eax
.global worker_before_acquire
worker_before_acquire:
 call 0x489a30
.global worker_after_acquire
worker_after_acquire:
 test eax,eax
 jnz worker_return
 mov eax,[esp+20]
 push eax
 push ebp
 call dword ptr [ebp+0xc4]
 mov esi,eax
 xor edi,edi
 test esi,esi
 jz worker_release
 /* No GPU dereference until native ownership; skip objects gone during unload. */
 mov eax,[esi+0x163c]
 test eax,eax
 jz worker_release
 push eax
 push esi
 call 0x47c070
 mov edi,eax
 test edi,edi
 jz worker_release
 push esi
 call dword ptr [esi+0xd4]
 test eax,eax
 jz worker_clear
 cmp byte ptr [esi+0x4e8],0
 je worker_clear
 cmp byte ptr [esi+0x4ec],0
 jne worker_clear
 cmp byte ptr [esi+0x4ee],0
 jne worker_clear
 cmp byte ptr [esi+0x4ef],0
 jne worker_clear
 cmp byte ptr [esi+0x4ff],0
 jne worker_clear
 cmp byte ptr [edi+0x6070],0
 je worker_clear
 push edi
 push esi
.global worker_before_fetch
worker_before_fetch:
 call dword ptr [edi+0x3e8]
worker_clear:
 mov byte ptr [edi+0x6071],0
worker_release:
 mov ebx,eax
 push 0
 push dword ptr [ebp+0x2064]
.global worker_before_release
worker_before_release:
 call 0x489710
 mov eax,ebx
worker_return:
 pop edi
 pop esi
 pop ebp
 pop ebx
 ret 8
.section .note.GNU-stack,"",@progbits
