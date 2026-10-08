.intel_syntax noprefix
.code32
.global _start
_start:
 movzx eax, dl
 and eax, 31
 # The native parser stores the CTA collection end at esp+16. Refuse
 # vendor payloads crossing either that boundary or the checksum byte.
 lea edi, [ecx+eax]
 sub edi, ebp
 cmp edi, 127
 ja skip
 cmp edi, dword ptr [esp+16]
 ja skip
 cmp eax, 3
 jb skip
 # A legacy HDMI VSDB must include its physical-address bytes.
 cmp word ptr [ecx], 0x0c03
 jne other
 cmp byte ptr [ecx+2], 0
 jne other
 cmp eax, 5
 jb skip
 # A shorter HDMI block must not inherit optional capability bytes from
 # a previously summarized vendor. Clear exactly the 31-byte vendor slot.
 xor edx, edx
 mov edi, 31
clear_hdmi:
 dec edi
 mov byte ptr [esi+edi+0x45], dl
 jnz clear_hdmi
 jmp copy
other:
 cmp word ptr [esi+0x45], 0x0c03
 jne forum
 cmp byte ptr [esi+0x47], 0
 je skip
forum:
 cmp word ptr [ecx], 0x5dd8
 jne copy
 cmp byte ptr [ecx+2], 0xc4
 je skip
copy:
 mov edi, eax
 xor eax, eax
again:
 mov dl, byte ptr [ecx+eax]
 mov byte ptr [esi+eax+0x45], dl
 inc eax
 cmp eax, edi
 jb again
 add ecx, edi
 jmp done
skip:
 add ecx, eax
 jmp done
.set done, 0x87432a
