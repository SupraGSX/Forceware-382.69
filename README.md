# Forceware 382.69

Custom NVIDIA 368.81-based driver for **Windows XP 32-bit**, adding Maxwell/Pascal desktop GPUs and improvements to rendering, display connections and NVIDIA Control Panel.

**Current stable: [11-1-2026](https://github.com/SupraGSX/Forceware-382.69/releases/tag/382.69-2026-11-01)**

Improves GP107/GP108 clock and power-management requests, reset cleanup and low-power controller initialization. Includes the existing rendering, compute, display and legacy-GPU boot fixes.

## Install

Run the EXE. When upgrading, choose **Custom (Advanced) → Perform a clean installation**, then restart. If needed, reselect your primary monitor in **Windows Display Properties**.

Windows Server 2003 x86 is also supported; optional GeForce Experience is omitted there. Bundled HD Audio, PhysX and nView retain their existing versions.

## Additional desktop GPUs

Added over stock 368.81:

- **GeForce Maxwell:** GTX 970, 980, 980 Ti and GTX TITAN X; additional desktop OEM variants of GTX 950 and 960.
- **GeForce Pascal:** GT 1030; GTX 1050, 1050 Ti, 1060 (3/5/6 GB), 1070, 1070 Ti, 1080, 1080 Ti, TITAN X and TITAN Xp.
- **Quadro:** M4000, M5000, M6000, M6000 24GB, P400, P600, P620, P1000, P2000, P2200, P4000, P5000 and P6000.

All original 368.81 INF files and device entries are retained, including notebook/OEM models. Newly added cards are desktop models; GP100 and GP108 models other than GT 1030 are excluded. INF inclusion does not establish individual model compatibility.

## Improvements

- **Stability:** Corrected shared hook branch targets for older GPUs. Pascal-specific PMU worker ownership, clock/power and completion adaptations preserve native 368.81 core paths on earlier families.
- **Rendering and compute:** Pascal initialization, OpenGL, CUDA, OpenCL and GPU PhysX fixes.
- **DisplayPort:** HBR2/HBR3 training, startup and display sleep/wake recovery, automatic 8-bit fallback, and scaling within the trained link's bandwidth.
- **HDMI:** Corrected HDMI identification, GPU/monitor-aware HDMI/DVI limits, SCDC setup and recovery, and native scaling with a 594 MHz ceiling.
- **Control Panel:** Restored Customize, separate Scaling and Overscan pages, and View system topology with EDID loading.

## Compatibility

- GT 1030 was tested on the MSI GDDR5 control. Fan-table and DDR4 memory-handling corrections passed ROM/parser and executable CPU tests; other boards and DDR4 hardware remain unqualified.
- The GP107 391.35 firmware path was tested on GTX 1050 Ti and Quadro P620. HBR3 remains unresolved on the tested GTX 1050 Ti; HBR2 works. P2200 compatibility is not confirmed. INF inclusion is not individual model validation.
- Automatic native DisplayPort scaling was tested at 60 Hz and does not carry a higher desktop refresh into lower-resolution games. Explicit higher-refresh modes remain available within link limits. HBR3 does not imply full DP 1.4 DSC, HDR or MST support.
- Automatic HDMI scaling was verified at 543.5 MHz; physical output at the exact 594 MHz ceiling remains unverified. Overscan resizing depends on the timing.
- Bounded PMU and concurrent-workload tests passed; long-run stability across physical systems remains unproven. Monitor audio was heard on the tested GTX 1050 Ti after restart; full GeForce Experience operation remains unverified.

## Source and rebuilding

See [REBUILDING.md](REBUILDING.md) for the tested November 1 reconstruction from stock 368.81, exact input/output hashes, patch sources and qualification limits. No earlier Forceware release is required.

The repository provides the patcher, added C/assembly routines and installer templates. **382.69 is this project's custom release number**, based on NVIDIA 368.81.

Original project code and documentation use [GPL-3.0-only](LICENSE), with a narrow [NVIDIA integration exception](NVIDIA-EXCEPTION.txt). Distributed modifications to covered code must include corresponding source under GPLv3. NVIDIA binaries, firmware and vendor-derived material retain their existing terms.
