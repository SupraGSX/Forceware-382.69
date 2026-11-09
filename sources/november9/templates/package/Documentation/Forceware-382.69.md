# Forceware 382.69

Custom NVIDIA 368.81-based driver for **Windows XP 32-bit**, adding Maxwell/Pascal desktop GPUs and improvements to rendering, display connections and NVIDIA Control Panel.

**Current stable: [11-9-2026](https://github.com/SupraGSX/Forceware-382.69/releases/tag/382.69-2026-11-09)**

Fixes DDR4 GT 1030 display corruption, improves GP107/GP108 power management and fan-controller handling, and enables GP107 DisplayPort HBR3 selection with improved monitor-timing detection.

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

- **Runtime:** Pascal initialization, clock/power management, request completion and reset handling, including GT 1030 DDR4 memory-clock programming. The older-GPU boot repair and native PMU worker ownership are retained.
- **Rendering and compute:** OpenGL, CUDA, OpenCL and GPU PhysX corrections, plus voltage-control and monitoring improvements.
- **DisplayPort:** HBR2/HBR3 selection and training, startup and sleep/wake recovery, automatic 8-bit fallback, and scaling within the trained link's bandwidth. GP107 is no longer restricted to HBR2.
- **HDMI:** Corrected HDMI identification, source/monitor/adapter-aware limits, SCDC setup and recovery, and native scaling. Eligible Fermi, Kepler and Maxwell 1 paths allow up to 340 MHz; eligible Maxwell 2/Pascal paths allow up to 594 MHz. DVI retains its own limits.
- **Control Panel:** Restored Customize, separate Scaling and Overscan pages, and View system topology with EDID loading.

## Tested hardware and limits

- November 9 has user-reported hardware validation on **Quadro M4000, GTX 1050 Ti, GT 640, and both GDDR5 and DDR4 GT 1030**. The DDR4 GT 1030 also passed a clean installation/reboot and six checked GDI/Direct3D/OpenGL rendering and relaunch cycles at 3440×1440 over HDMI.
- GTX 1050 Ti DisplayPort was confirmed at **3440×1440/175 Hz, HBR3 ×4, RGB 8-bit** during testing of the included link policy. Supported modes still depend on the card, cable, monitor and successful training. This does not establish DSC, HDR or MST support.
- Automatic DisplayPort scaling requires a preferred timing matching the requested refresh; it does not automatically carry a higher desktop refresh into lower-resolution games. Explicit supported higher-refresh modes remain available.
- HDMI output was confirmed at 543.5 MHz on Pascal and 319.75 MHz on GT 640. Exact 594 MHz output and universal 340 MHz operation remain unverified. HDMI has no DisplayPort-style link-quality fallback; overscan resizing depends on the timing.
- Quadro P620 passed earlier firmware-integration testing; the latest changes have not been requalified on it. P2200 and other untested models remain unconfirmed. Bounded tests do not establish all-board or long-run stability, or resolution of every reported freeze. Full GeForce Experience operation remains unverified.

## Source and rebuilding

See [REBUILDING.md](https://github.com/SupraGSX/Forceware-382.69/blob/main/REBUILDING.md) for the November 9 reconstruction from **stock 368.81**, exact input/output hashes, patch sources and qualification limits. No earlier Forceware release is required.

The repository provides the patcher, added C/assembly routines and installer templates. **382.69 is this project's custom release number**, based on NVIDIA 368.81.

Original project code and documentation use [GPL-3.0-only](../license.txt), with a narrow [NVIDIA integration exception](https://github.com/SupraGSX/Forceware-382.69/blob/main/NVIDIA-EXCEPTION.txt). Distributed modifications to covered code must include corresponding source under GPLv3. NVIDIA binaries, firmware and vendor-derived material retain their existing terms.
