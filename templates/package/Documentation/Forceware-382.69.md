# Forceware 382.69

Custom NVIDIA 368.81-based driver for **Windows XP 32-bit**, released as **Forceware 382.69**.

**Build: 10-4-2026 — GP107 support is experimental**

Improved DisplayPort and HDMI handling, with Control Panel fixes bringing custom resolutions and DisplayPort scaling closer to 355.98 behavior.

**Additional desktop INF entries over stock 368.81**

- GeForce GTX 970, 980, 980 Ti; GTX TITAN X (Maxwell).
- GeForce GTX 1060 (3/5/6 GB), 1070, 1070 Ti, 1080, 1080 Ti; TITAN X (Pascal), TITAN Xp.
- Quadro M4000, M5000, M6000, M6000 24GB; P2000, P2200, P4000, P5000, P6000.
- Additional desktop OEM variants of GTX 950 and GTX 960.

Mobile, GP100, GP107 and GP108 GPUs are excluded. These are INF additions, not individual validation of every model. See ListDevices.txt for the complete Maxwell/Pascal INF list.

GP107 display INF entries are withheld following reported Code 10 failures. Experimental code and internal name records are retained for further development.

**Included fixes**

- CUDA, OpenCL and GPU PhysX initialization corrected through missing internal GPU-name records; verified on GTX 1080 Ti.
- OpenGL display-class initialization fixed, verified on GTX 1080 Ti.
- DisplayPort HBR2/HBR3 training and extended capability detection, with mode selection based on a successfully trained link and automatic 8-bit fallback when needed.
- HDMI 2.0 identification, SCDC scrambling/high-speed clock-ratio handling, and bounded setup retries with safe-mode recovery on failure.
- HDMI/DVI handling with GPU/monitor-aware limits and a 594 MHz HDMI ceiling.
- Corrected DisplayPort identification, restored **Customize**, and improved scaling/fixed-aspect-ratio settings in NVIDIA Control Panel.
- **View system topology** and EDID loading unlocked.
- DisplayPort startup preparation and restoration of saved lane settings after display sleep.
- Windows Server 2003 x86 installation compatibility; GeForce Experience is omitted there.

HBR3 support does not imply full DP 1.4 DSC/HDR/MST support.

The 10-6-2026 build continues the October 5 stable release with Server 2003 x86 installer compatibility, improved DisplayPort startup, and DisplayPort sleep/wake restoration. GP107 remains excluded from the display INF.


Display driver version: 6.14.13.8269; INF version: 10.18.13.8269. HD Audio, PhysX and other component versions are unchanged. This is a custom distribution, not an official NVIDIA 382.69 release.

Validation includes accelerated D3D9 and normal 3440x1440/100 output on GTX 980 Ti over both DisplayPort and HDMI. Earlier Pascal testing covered Quadro P4000 and GTX 1080 Ti. The latest link/recovery changes were tested on GTX 980 Ti; individual boards and monitors are not universally validated. The 594 MHz policy ceiling is not a confirmed 594 MHz visible-picture result.

See [DisplayPort policy](DisplayPort-update.md) and [HDMI setup recovery](HDMI-SCDC-recovery.md) for implementation details. The matching reconstruction files are provided alongside the installer.

See [OpenGL initialization](OpenGL-update.md) for the added class recognition and validation.

Build date: `10/06/2026` in the display INF and rebuilt display metadata. See [GP107 details](GP107-experimental.md).
