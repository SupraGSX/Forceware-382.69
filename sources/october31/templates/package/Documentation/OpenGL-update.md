# OpenGL display-class initialization

This update adds display class `0x9870` to the supported-class list in XP's `nvoglnt.dll`. The original eleven entries and the existing selection routine are preserved. Both object creation and teardown use the extended list.

On GTX 1080 Ti, the driver advertises this class, but the old OpenGL list does not recognize it. The required display parent is consequently skipped and a later allocation fails, leaving graphics-context callbacks uninitialized. Recognizing the advertised class allows the existing initialization to complete.

The 378.78 x86 OpenGL driver contains the same list with `0x9870` prepended. Its DLL is not installed by this update; the XP OpenGL implementation and shader compiler are retained.

## Implementation

A twelve-entry table is placed at preferred VA `0x6A45F7A0` in verified unused `.rdata` space. The two lookup sites at preferred VAs `0x69E96249` and `0x69E963CB` are redirected to it and their counts change from eleven to twelve. Existing relocation records cover the pointers. The section virtual size and PE checksum are updated.

The preserved entries are `9770, 9570, 9470, 9270, 9170, 9070, 8570, 8370, 8870, 8270, 5070`. Selection still requires a class actually advertised by the driver. No forced-success return, GPU identity change, firmware replacement or foreign context layout is introduced.

## Validation

After booting the file-based update with GTX 1080 Ti as the primary GPU, glxgears and GPU Caps Viewer 1.37's Simple Mesh, Furry Cube, Illuminated Torus and Tessellation render without debugger assistance. All four GPU Caps Viewer processes exit normally. D3D9 hardware vertex processing and VS3/PS3 pass 64 draws with full target readback. Other cards and applications still require regression testing.

## Source references

At Linux commit `adc218676eef25575469234709c2d87185ca223a`, `drivers/gpu/drm/nouveau/include/nvif/class.h` defines `GP102_DISP` as `0x9870`. `nvkm/engine/device/base.c` assigns GP102 and GP104 to `gp102_disp_new`; `nvkm/engine/disp/gp102.c` exposes this root class while reusing older display methods. These are implementation guides, not Windows structure definitions.

At Mesa commit `f1f246cfda65eff82fba3be1caf2d23bdeda60cc`, `src/nouveau/codegen/nv50_ir_target.cpp` uses the GM107 compiler family for Maxwell and Pascal. The observed Windows failure occurs before rendering initialization; the unchanged NVIDIA compiler works in the listed tests.

The reconstruction manifest contains the complete guarded stock-to-final edits. The separate `sources/opengl-display-class.py` recipe describes and verifies this addition to the preceding Forceware build.
