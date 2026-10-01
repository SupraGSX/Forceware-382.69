# Forceware 382.69

Custom NVIDIA 368.81-based driver for **Windows XP 32-bit**, released as **Forceware 382.69**.

**Additional desktop INF entries over stock 368.81**

- GeForce GTX 970, 980, 980 Ti; GTX TITAN X (Maxwell).
- GeForce GTX 1050, 1050 Ti, 1060 (3/5/6 GB), 1070, 1070 Ti, 1080, 1080 Ti; TITAN X (Pascal), TITAN Xp.
- Quadro M4000, M5000, M6000, M6000 24GB; GP100; P400, P600, P620, P1000, P2000, P2200, P4000, P5000, P6000.
- Additional desktop OEM variants of GTX 950 and GTX 960.

Mobile and GP108 GPUs excluded. These are INF additions, not individual validation of every model.

**Included fixes**

- DisplayPort 1.4 HBR3 link-rate support, HBR2/HBR3 training, extended capability detection and automatic 8-bit fallback.
- HDMI 2.0 identification and SCDC scrambling/high-speed clock-ratio handling.
- Updated HDMI/DVI handling with GPU/monitor-aware limits and a 594 MHz HDMI ceiling.
- NVIDIA Control Panel **Customize** button restored.
- **View system topology** and EDID loading unlocked.

[Download the installer](https://github.com/SupraGSX/Forceware-382.69/releases/latest)


This is a custom 368.81-derived distribution, not an official NVIDIA 382.69 release. Display driver file version: 6.14.13.8269; INF version: 10.18.13.8269. HD Audio, PhysX and other component versions are unchanged.

Validation: the installation payload passed normal XP setup/reboot, version checks and 64 accelerated D3D9 shader/readback checks on a GTX 1080 Ti. Native HDMI 3440x1440/100 Hz at 543.5 MHz was physically confirmed. The 594 MHz policy ceiling is not a confirmed 594 MHz visible-picture result. DP testing used P4000 and GTX 1080 Ti. This does not establish every listed GPU, full DP 1.4 features such as DSC/HDR/MST, every monitor, physical DVI, audio playback or long-term stability.

Nouveau/Mesa references guided independent Windows analysis; Linux code was not copied. Recorded source pins: Linux adc218676eef25575469234709c2d87185ca223a; Mesa f1f246cfda65eff82fba3be1caf2d23bdeda60cc. Relevant Nouveau sources include drivers/gpu/drm/nouveau/nvkm/engine/disp/gp100.c, gp102.c, gm200.c and gf119.c.
