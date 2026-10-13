# Forceware 382.69

Custom NVIDIA 368.81-based driver for **Windows XP 32-bit**, adding Maxwell/Pascal desktop GPUs and improvements to rendering, display connections and NVIDIA Control Panel.

**Current stable: [10-12-2026](https://github.com/SupraGSX/Forceware-382.69/releases/tag/382.69-2026-10-12)**

Improved DisplayPort/HDMI audio detection, multi-block EDID handling, corrected HD Audio installation, optional GeForce Experience installer visibility and hardened HDMI capability validation.

## Install

Run the EXE. When upgrading, choose **Custom (Advanced) → Perform a clean installation**, then restart. If needed, reselect your primary monitor in **Windows Display Properties**.

Windows Server 2003 x86 is also supported; optional GeForce Experience is omitted there. Bundled HD Audio, PhysX and nView retain their existing versions.

## Additional desktop GPUs

Added over stock 368.81:

- **GeForce Maxwell:** GTX 970, 980, 980 Ti and GTX TITAN X; additional desktop OEM variants of GTX 950 and 960.
- **GeForce Pascal:** GTX 1050, 1050 Ti, 1060 (3/5/6 GB), 1070, 1070 Ti, 1080, 1080 Ti, TITAN X and TITAN Xp.
- **Quadro:** M4000, M5000, M6000, M6000 24GB, P400, P600, P620, P1000, P2000, P2200, P4000, P5000 and P6000.

Mobile, GP100 and GP108 GPUs are excluded. See the [complete stable device list](https://github.com/SupraGSX/Forceware-382.69/blob/382.69-2026-10-11-rollback/desktop-gpus.json).

## Improvements

- **Stability:** PMU receive and shared memory-port synchronization corrections.
- **Rendering and compute:** Pascal initialization, OpenGL, CUDA, OpenCL and GPU PhysX fixes.
- **DisplayPort:** HBR2/HBR3 training, startup and display sleep/wake recovery, automatic 8-bit fallback, and scaling within the trained link's bandwidth.
- **HDMI:** Corrected HDMI identification, GPU/monitor-aware HDMI/DVI limits, SCDC setup and recovery, and native scaling with a 594 MHz ceiling.
- **Control Panel:** Restored Customize, separate Scaling and Overscan pages, and View system topology with EDID loading.

## Compatibility

- GP107 was validated on GTX 1050 Ti and defaults to HBR2 or lower; HBR3 remains unresolved on that card. P620/P2200 compatibility is not confirmed. INF inclusion is not individual model validation.
- Automatic native DisplayPort scaling was tested at 60 Hz and does not carry a higher desktop refresh into lower-resolution games. Explicit higher-refresh modes remain available within link limits. HBR3 does not imply full DP 1.4 DSC, HDR or MST support.
- Automatic HDMI scaling was verified at 543.5 MHz; physical output at the exact 594 MHz ceiling remains unverified. Overscan resizing depends on the timing.
- The PMU corrections passed VM and concurrent-transfer tests; physical-hardware confirmation remains pending. October 12 audio endpoint/playback-buffer and installer tests passed, but audible output and full GeForce Experience operation were not verified.

## Source and rebuilding

Use the source tag matching your installer: [stable rebuilding guide](https://github.com/SupraGSX/Forceware-382.69/blob/382.69-2026-10-11-rollback/REBUILDING.md) · [October 12 prerelease guide](https://github.com/SupraGSX/Forceware-382.69/blob/382.69-2026-10-12/REBUILDING.md).

The repository provides the patcher, added C/assembly routines and installer templates. **382.69 is this project's custom release number**, based on NVIDIA 368.81.

Original project code and documentation use [GPL-3.0-only](LICENSE), with a narrow [NVIDIA integration exception](NVIDIA-EXCEPTION.txt). Distributed modifications to covered code must include corresponding source under GPLv3. NVIDIA binaries, firmware and vendor-derived material retain their existing terms.
