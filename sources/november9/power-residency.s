.intel_syntax noprefix
.code32
.section .text
# Only the existing per-adapter391 image provider gains the same proved
# flag producer used by the retained older provider. All other ownership
# identities replay the original full guard. No machine-global selection.
.macro check gpu, yes, no
 pushfd
 push ecx
 push edx
 mov ecx,[\gpu+0x16e0]
 test ecx,ecx
 jz 2f
 call 1f
1: pop edx
 sub edx,OFFSET FLAT:1b
 lea edx,[edx+0xf0d3a3]
 cmp [ecx+0x1bc],edx
 jne 2f
 pop edx
 pop ecx
 popfd
 jmp \yes
2: pop edx
 pop ecx
 popfd
 jmp \no
.endm
.global parser_guard, constructor_guard
parser_guard:
 check edi,0xdcb1a5,0xdcb174
constructor_guard:
 check ebp,0xdcb1f2,0xdcb1c1
