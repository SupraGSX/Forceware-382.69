# Forceware 382.69

Custom NVIDIA 368.81-based driver for **Windows XP 32-bit**, released as **Forceware 382.69**.

**Build: 10-5-2026**

Improved DisplayPort and HDMI handling, with Control Panel fixes bringing custom resolutions and DisplayPort scaling closer to 355.98 behavior.

**Additional desktop INF entries over stock 368.81**

- GeForce GTX 970, 980, 980 Ti; GTX TITAN X (Maxwell).
- GeForce GTX 1060 (3/5/6 GB), 1070, 1070 Ti, 1080, 1080 Ti; TITAN X (Pascal), TITAN Xp.
- Quadro M4000, M5000, M6000, M6000 24GB; P2000, P2200, P4000, P5000, P6000.
- Additional desktop OEM variants of GTX 950 and GTX 960.

Mobile, GP100, GP107 and GP108 GPUs are excluded. These are INF additions, not individual validation of every model. See [the complete Maxwell/Pascal INF list](desktop-gpus.json).

Experimental GP107 support is suspended because end users still report Code 10. GP107 entries are removed from the display INF; experimental code and internal name records are retained for further development.

**Included fixes**

- CUDA, OpenCL and GPU PhysX initialization corrected through missing internal GPU-name records; verified on GTX 1080 Ti.
- OpenGL display-class initialization fixed, verified on GTX 1080 Ti.
- DisplayPort HBR2/HBR3 training and extended capability detection, with mode selection based on a successfully trained link and automatic 8-bit fallback when needed.
- HDMI 2.0 identification, SCDC scrambling/high-speed clock-ratio handling, and bounded setup retries with safe-mode recovery on failure.
- HDMI/DVI handling with GPU/monitor-aware limits and a 594 MHz HDMI ceiling.
- Corrected DisplayPort identification, restored **Customize**, and improved scaling/fixed-aspect-ratio settings in NVIDIA Control Panel.
- **View system topology** and EDID loading unlocked.

HBR3 support does not imply full DP 1.4 DSC/HDR/MST support.

The 10-5-2026 build adds the CUDA/OpenCL/GPU PhysX correction and consistent display build dates, and removes GP107 display INF entries.

[Download the installer](https://github.com/SupraGSX/Forceware-382.69/releases/latest)

When updating an existing driver installation, select **Custom (Advanced) → Perform a clean installation**, then restart. This ensures the revised display files replace the earlier build.

**Source and rebuilding**

[Read the build guide](REBUILDING.md) for the final patches, required NVIDIA inputs, reproduction commands and validation results. The repository includes the Python patcher, C/assembly routines and installer templates.

**License**

The project's original code and documentation are licensed under [GPL-3.0-only](LICENSE), with a narrow [NVIDIA integration exception](NVIDIA-EXCEPTION.txt). Distributed modifications to the covered code must remain under GPLv3 and include corresponding source.

NVIDIA binaries, firmware, vendor-derived installer files and NVIDIA-derived portions of the patch data retain their existing terms. This project does not relicense NVIDIA's material.

Build date: `10/05/2026` in the display INF and rebuilt display metadata. See [GP107 details](templates/package/Documentation/GP107-experimental.md).
