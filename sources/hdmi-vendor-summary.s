.intel_syntax noprefix
.code32
.global _start
_start:
  movzx eax, dl
  and eax, 31
  cmp eax, 3
  jb skip
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
.fill 55-(.-_start),1,0x90
.set done, _start+0x7a
