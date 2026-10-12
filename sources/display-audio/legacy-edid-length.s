.intel_syntax noprefix
.section .text
.global _start
# Wrap the existing 8-argument stdcall copy at preferred VA 592D50.
# No EDID contents, capabilities, timing or firmware are changed.
# The legacy interface already copies min(native-cache-size,256).
# Keep that exact count in a private frame while forwarding the existing copy.
_start:
 push ebp
 mov ebp,esp
 sub esp,4
 mov edx,[ebp+0x20]
 mov [ebp-4],edx
 push dword ptr [ebp+0x24]
 push dword ptr [ebp+0x20]
 push dword ptr [ebp+0x1c]
 push dword ptr [ebp+0x18]
 push dword ptr [ebp+0x14]
 push dword ptr [ebp+0x10]
 push dword ptr [ebp+0x0c]
 push dword ptr [ebp+0x08]
 call native_copy
 test eax,eax
 jnz finish
 # Original caller SP is frame+28; parsed EDID format at SP+14.
 mov ecx,[ebp+0x3c]
 cmp ecx,0x10
 jb continue_original_default
 cmp ecx,0x14
 jbe version1
 cmp ecx,0x20
 jne continue_original_default
 jmp want256
version1:
 cmp ecx,0x13
 jb want128
 cmp byte ptr [ebx+0x7e],0
 je want128
want256:
 cmp dword ptr [ebp-4],256
 jb want128
 mov ecx,256
 jmp report
want128:
 mov ecx,128
 cmp dword ptr [ebp-4],128
 jae report
 mov ecx,[ebp-4]
report:
 mov [ebp+0xa4],ecx
continue_original_default:
 # Skip the old exact-one-extension size selection; normal error path retained.
 add dword ptr [ebp+4],0x42
finish:
 mov esp,ebp
 pop ebp
 ret 0x20
