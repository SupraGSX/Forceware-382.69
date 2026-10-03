# Forceware 382.69

Custom NVIDIA 368.81-based driver for **Windows XP 32-bit**, released as **Forceware 382.69**.

**Latest update: 10-3-26**

Improved DisplayPort and HDMI handling, with Control Panel fixes bringing custom resolutions and DisplayPort scaling closer to 355.98 behavior.

**Additional desktop INF entries over stock 368.81**

- GeForce GTX 970, 980, 980 Ti; GTX TITAN X (Maxwell).
- GeForce GTX 1060 (3/5/6 GB), 1070, 1070 Ti, 1080, 1080 Ti; TITAN X (Pascal), TITAN Xp.
- Quadro M4000, M5000, M6000, M6000 24GB; P2000, P2200, P4000, P5000, P6000.
- Additional desktop OEM variants of GTX 950 and GTX 960.

Mobile, GP100, GP107 and GP108 GPUs are excluded. These are INF additions, not individual validation of every model. See [the complete Maxwell/Pascal INF list](desktop-gpus.json).

**Included fixes**

- DisplayPort HBR2/HBR3 training and extended capability detection, with mode selection based on a successfully trained link and automatic 8-bit fallback when needed.
- HDMI 2.0 identification, SCDC scrambling/high-speed clock-ratio handling, and bounded setup retries with safe-mode recovery on failure.
- HDMI/DVI handling with GPU/monitor-aware limits and a 594 MHz HDMI ceiling.
- Corrected DisplayPort identification, restored **Customize**, and improved scaling/fixed-aspect-ratio settings in NVIDIA Control Panel.
- **View system topology** and EDID loading unlocked.

HBR3 support does not imply full DP 1.4 DSC/HDR/MST support.

[Download the installer](https://github.com/SupraGSX/Forceware-382.69/releases/latest)

**Source and rebuilding**

[Read the build guide](REBUILDING.md) for the final patches, required NVIDIA inputs, reproduction commands and validation results. The repository includes the Python patcher, C/assembly routines and installer templates.

**License**

The project's original code and documentation are licensed under [GPL-3.0-only](LICENSE), with a narrow [NVIDIA integration exception](NVIDIA-EXCEPTION.txt). Distributed modifications to the covered code must remain under GPLv3 and include corresponding source.

NVIDIA binaries, firmware, vendor-derived installer files and NVIDIA-derived portions of the patch data retain their existing terms. This project does not relicense NVIDIA's material.
