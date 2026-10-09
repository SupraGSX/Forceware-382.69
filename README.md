# Forceware 382.69

Custom NVIDIA 368.81-based driver for **Windows XP 32-bit**, with additional Maxwell/Pascal desktop GPUs and improvements to rendering, display connections and NVIDIA Control Panel.

**Build: 10-9-2026** · [Download the installer](https://github.com/SupraGSX/Forceware-382.69/releases/latest) · [Rebuilding guide](REBUILDING.md)

## Install

Run the EXE and follow the NVIDIA installer. When upgrading, select **Custom (Advanced) → Perform a clean installation**, then restart.

Windows Server 2003 x86 installation is also supported; optional GeForce Experience is omitted there. Bundled HD Audio, PhysX and nView components retain their existing versions.

## Additional desktop GPUs

The display INF adds these models and variants over stock 368.81:

- **GeForce Maxwell:** GTX 970, 980, 980 Ti and GTX TITAN X; additional desktop OEM variants of GTX 950 and 960.
- **GeForce Pascal:** GTX 1050, 1050 Ti, 1060 (3/5/6 GB), 1070, 1070 Ti, 1080, 1080 Ti, TITAN X and TITAN Xp.
- **Quadro:** M4000, M5000, M6000, M6000 24GB, P400, P600, P620, P1000, P2000, P2200, P4000, P5000 and P6000.

Mobile, GP100 and GP108 GPUs are excluded. GP107 support has been validated on GTX 1050 Ti; the other included GP107 models have not been individually tested. See the [complete device list](desktop-gpus.json).

## Improvements

- **Rendering and compute:** Pascal initialization fixes, OpenGL display-class recognition, and corrected CUDA, OpenCL and GPU PhysX initialization.
- **DisplayPort:** HBR2/HBR3 training, startup and display sleep/wake recovery, automatic 8-bit fallback when needed, and native scaling within the successfully trained link's bandwidth.
- **HDMI:** Corrected vendor-block identification, GPU/monitor-aware HDMI/DVI limits, SCDC setup and failure recovery, and native scaling with a 594 MHz ceiling.
- **Control Panel:** Corrected display classification, restored **Customize**, separate **Scaling** and **Overscan** pages, and unlocked **View system topology** with EDID loading.

## Compatibility notes

- GP107 defaults to HBR2 and lower DisplayPort rates; HBR3 output remains unresolved on the tested GTX 1050 Ti. Other supported GPU families retain their existing link policy. HBR3 support does not establish full DisplayPort 1.4 DSC, HDR or MST support.
- Automatic native DisplayPort scaling requires a preferred timing matching the requested refresh. It was tested at 60 Hz and does not automatically carry a higher desktop refresh into lower-resolution games. Explicit higher-refresh native modes remain available when supported.
- Automatic HDMI scaling was verified at 543.5 MHz on GTX 1080 Ti. The 594 MHz ceiling is subject to GPU/monitor limits; physical output at that exact clock remains unverified.
- Scaling choices follow native capability checks. Overscan resizing is available only for timings supported by NVIDIA's native resize implementation.

See the [validation results and limits](REBUILDING.md#7-validation-and-limits) for tested configurations.

## Source and license

The repository contains the patcher, C/assembly routines and installer templates. [REBUILDING.md](REBUILDING.md) documents the required NVIDIA inputs, reconstruction commands, implementation and validation. **382.69 is this project's custom release number**, based on NVIDIA 368.81.

Original project code and documentation use [GPL-3.0-only](LICENSE), with a narrow [NVIDIA integration exception](NVIDIA-EXCEPTION.txt). Distributed modifications to the covered code must include corresponding source under GPLv3. NVIDIA binaries, firmware and vendor-derived material retain their existing terms.
