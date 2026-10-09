# GP107 support

Build 10-9-2026 includes desktop GTX 1050 (1C81/1C83), GTX 1050 Ti (1C82), Quadro P1000 (1CB1), P600 (1CB2), P400 (1CB3) and P620 (1CB6). GTX 1050 Ti has been hardware tested. The other GP107 models have not been individually tested; mobile GPUs, GP100 and GP108 remain excluded.

## Initialization

The XP driver retains GP106 registration and adds a separate GP107 family table. Semantically matching XP callbacks are reused alongside GP107 context values and intact graphics firmware from the pinned 376.84 donor. FECS and GPCCS now select matching bootloaders as well as the GP107 application/signature resources. Signed firmware instructions and signatures are unchanged; no authentication check is bypassed.

The GP107 GPU-limit callback describes one PPC per GPC and three TPCs, while preserving the original XP callbacks that discover actual fuse counts and masks and generate topology. The original GP106 GPU constructor and all callback slots except the GP107 limit query remain intact. Newer Windows object offsets are not copied into XP structures. The capability flag at XP offset 0x62D was mapped by comparison with neighboring fields and has been exercised on GTX 1050 Ti; its semantics are not completely documented.

GP107 alone defaults to HBR2 and lower DisplayPort rates. This is a conservative workaround: HBR3 could be programmed but did not produce a visible picture on the tested card, including supported-driver comparisons. Real link training, receiver checks, depth selection and the existing configuration override remain in place. Other GPU families retain their prior policy. HDMI handling is unchanged.

## Reproduction and evidence

The complete stock-to-final recipe is in patches.json. The GP107 assembly sources cover registration/context setup, matching graphics boot resources, chip limits and the scoped DisplayPort policy. verify_sources.py assembles these blocks and checks the exact inserted instructions, resource hashes, corrected names and final miniport hash.

Isolated native x86 execution checks covered registration failure propagation, original XP constructors/selector, stack balance, relocated pointers, context constants and unchanged GP106 callbacks. The DisplayPort hook was tested across 102 chip identities at both preferred and relocated addresses. These tests do not execute the GPU or prove every board works.

GTX 1050 Ti testing passed hardware Direct3D9, OpenGL, CUDA, OpenCL and GPU PhysX. DisplayPort HBR2 x4 and HDMI produced a confirmed normal native-resolution picture. GPU PhysX must be enabled in NVIDIA Control Panel and in the application; correcting a displayed GPU name does not override a saved CPU-only selection. Use a fresh application process after changing that selection.

Nouveau at Linux commit adc218676eef25575469234709c2d87185ca223a uses shared GP104 display/FIFO/MMU/framebuffer/ACR/SEC2 implementations for GP107 in drivers/gpu/drm/nouveau/nvkm/engine/device/base.c, with GP107 graphics firmware and limits in engine/gr/gp107.c and context values in engine/gr/ctxgp107.c. Mesa commit f1f246cfda65eff82fba3be1caf2d23bdeda60cc selects the common GM107 compiler family in src/nouveau/codegen/nv50_ir_target.cpp. These references guided comparison; Linux object layouts and code were not transplanted into XP.
