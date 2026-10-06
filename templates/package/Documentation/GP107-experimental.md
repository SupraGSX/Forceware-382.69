# GP107 experimental initialization

The 10-6-2026 build retains experimental GP107 code and internal name records but removes all seven GP107 display INF entries. GTX 1050 Ti testers reported Code 10 with the earlier experimental builds; GP107 initialization is not working reliably enough for inclusion.

Excluded desktop entries: GTX 1050 (1C81/1C83), GTX 1050 Ti (1C82), Quadro P1000 (1CB1), P600 (1CB2), P400 (1CB3), and P620 (1CB6). Mobile GPUs, GP100 and GP108 also remain excluded. Existing PhysX installer entries are retained separately.

## Implementation

The XP driver already has a GP107 identity but lacks its family registration. A hook at preferred VA `0x46F7AA` preserves the original GP106 registration and then registers GP107 index `0x3B` through a separate 82-pointer table. Registration failure is propagated. Existing GP106 class/engine tables and semantically matching XP GP104 callbacks are retained; the GPU identity is not changed.

The appended block starts at `0xD07C40`. Its FECS/GPCCS constructors and graphics constructor use intact matched GP107 signatures and an 87,842-byte graphics bundle from the pinned 376.84 x86 donor. The existing ACR, SEC2, VPR and boot-descriptor adaptation remain unchanged. Donor firmware instructions and signatures are not edited.

GP107 context values are applied through independently mapped XP callbacks and XP field offsets. Newer Windows object offsets are not copied. The capability flag at XP offset `0x62D` is an inferred mapping and remains a hardware-validation target. The additional GP107 graphics-bundle directory types also need hardware validation.

The complete stock-to-final byte and firmware recipe is in `patches.json`. `sources/gp107/gp107.s` and `gp107.ld` rebuild the inserted code. `verify_sources.py` checks the compiled block, resource hashes, and final miniport hash. The OpenGL patch remains in `nvoglnt.dll`, independently of this miniport addition.

## Evidence and limits

The exact GP107 miniport previously passed 166 offline i386 execution checks across its preferred and relocated addresses: registration, original selector, failure propagation, XP constructor calls, stack balance, firmware pointers, context constants and GP106 preservation. The registration allocator was substituted; these checks do not execute a GPU, firmware or the Windows kernel. They do not prove GP107 startup or cure a reported Code 10.

The exact OpenGL DLL passed glxgears and four GPU Caps Viewer demos on primary GTX 1080 Ti, plus D3D9 draw/readback checks. The combined package has not acquired a new GP107 hardware pass merely by including both changes.

Nouveau at Linux commit `adc218676eef25575469234709c2d87185ca223a` assigns GP104 and GP107 the same display/FIFO/MMU/framebuffer/ACR/SEC2 constructors in `drivers/gpu/drm/nouveau/nvkm/engine/device/base.c`, with GP107-specific GR setup and context values in `engine/gr/gp107.c` and `engine/gr/ctxgp107.c`. Mesa commit `f1f246cfda65eff82fba3be1caf2d23bdeda60cc`, `src/nouveau/codegen/nv50_ir_target.cpp`, selects the common GM107 compiler family for Maxwell and Pascal. These references guided comparison; Linux layouts or code were not copied into the XP driver.

## First hardware checks

Use a recoverable XP installation and keep the preceding driver available. Make the test GPU the primary VGA device. Install normally, reboot, and confirm Device Manager's driver date is October 4, 2026. Check device status before trying dxdiag DirectDraw/Direct3D tests, OpenGL demos, and familiar games. If startup fails, use Safe Mode to revert the driver. Record the card model/PCI ID, device status and any stop code. File hashes distinguish exact binaries if the date alone is insufficient.
