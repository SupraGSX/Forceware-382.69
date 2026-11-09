# Rebuilding Forceware 382.69

This guide covers the **November 1, 2026 build**. **382.69 is the project's custom version number**, based on NVIDIA 368.81 for Windows XP 32-bit. The [October 19 stable reconstruction](REBUILDING-10-19.md) remains available with its original inputs and hashes.

## Reconstruct November 1

Start with **stock NVIDIA 368.81 XP 32-bit international** and the six vendor firmware donors below. No previous Forceware 382.69 installer is required.

| Input / argument | Required SHA-256 |
|---|---|
| [368.81 XP installer](https://us.download.nvidia.com/Windows/368.81/368.81-desktop-winxp-32bit-international.exe), `--stock` | `eaaef0650b6c6a99a2ed70d5e15aaf5221570ae596ca51784ff5e6fc7e5482f1` |
| [Quadro 376.84 x86](https://us.download.nvidia.com/Windows/Quadro_Certified/376.84/376.84-quadro-grid-desktop-notebook-win8-win7-32bit-international-whql.exe), `--quadro` | `84fcd8f31466956f40f1aebc833ef4b23c30b0077e61a842257b4076e4482633` |
| [GeForce 378.78 x86](https://us.download.nvidia.com/Windows/378.78/378.78-desktop-win8-win7-32bit-international-whql.exe), `--geforce` | `467bdc2e47f4f36330ed011520b9ac79e3051c20728a60e5a2ecebda0228152f` |
| [GeForce 381.65 x86](https://us.download.nvidia.com/Windows/381.65/381.65-desktop-win8-win7-32bit-international-whql.exe), `--gp102` | `1de048708f30399a5f33f15b4ac3e3609db0c626b71a5596d2528c3585cb0d09` |
| [Quadro 390.77 x86](https://us.download.nvidia.com/Windows/Quadro_Certified/390.77/390.77-quadro-desktop-notebook-win8-win7-32bit-international-whql.exe), `--gp107` | `583a7c051bbe933a558ec1c000a0077e0be0cdf03717e366d371e9b3b2006358` |
| [GeForce 382.23 x86](https://us.download.nvidia.com/Windows/382.23/382.23-desktop-win8-win7-32bit-international-whql.exe), `--gp108` | `927f556d98494769b5a09e48edd3491a38fff52aab9b7c1f87ed9b8121c9d96b` |
| [GeForce 391.35 x86](https://us.download.nvidia.com/Windows/391.35/391.35-desktop-win8-win7-32bit-international-whql.exe), `--pascal391` | `29d87a800925ff50a1b14c3007ab6913c375faf795185a3da5ade139b685c6db` |

The first hash is for the **complete stock installer**. All other hashes are for each donor's **expanded `Display.Driver/nvlddmkm.sys`**, not its installer. Extract the donor packages with 7-Zip; if the module is stored as `nvlddmkm.sy_`, extract that CAB member too. Keep identically named modules in separate directories. No donor installation is necessary.

These inputs reconstruct all retained resources, including older inactive copies needed for byte-exact reproduction. The final patched dispatch tables determine the active firmware paths; supplying an older donor does not switch GP107/GP108 away from the current 391.35 paths.

Use Python 3.9+ and `7z`:

```bash
python3 rebuild_november1.py \
  --stock inputs/368.81-desktop-winxp-32bit-international.exe \
  --quadro inputs/quadro-376.84/nvlddmkm.sys \
  --geforce inputs/geforce-378.78/nvlddmkm.sys \
  --gp102 inputs/geforce-381.65/nvlddmkm.sys \
  --gp107 inputs/quadro-390.77/nvlddmkm.sys \
  --gp108 inputs/geforce-382.23/nvlddmkm.sys \
  --pascal391 inputs/geforce-391.35/nvlddmkm.sys \
  --out build-november1
```

The output directory must not exist. The builder validates all seven input hashes and the complete stock package/Control Panel inventories, expands the required stock files, extracts and hashes 130 donor resources, copies guarded stock data ranges and applies all final patches/templates. It then checks every resulting payload hash, rebuilds both installers and extracts them again for verification. It does not install or execute the driver.

Outputs include `Forceware 382.69 (11-1-2026).exe`, the extracted `Forceware 382.69/` directory and `rebuild-result.json`. The [stock-to-release manifest](../sources/november1/stock-manifest.json) records every input/output hash, donor descriptor, stock-copy range, patch boundary and final package member. The tested recipe reproduced the final EXE byte-for-byte, including **636 non-generated package files and all 469 Control Panel files**. Compression-tool differences can change archive bytes; all runtime files and Control Panel members must still match exactly.

| File | SHA-256 |
|---|---|
| November 1 EXE | `27e3f16104318b5d6f2cd8c67b380379b143db6878fbdfa39544ea438015eab4` |
| `Display.Driver/nv4_mini.sys` | `f5ed0da5bc146316839f712620c32307f41b46bfd24ee254949ce444e8b79cdf` |
| `Display.Driver/nvapi.dll` | `2bebab9b3f6df479c20f9b6c75261cb37b037a3fad522b15e40d21082e7fcf47` |

For an independent compiled-byte check, use GCC with 32-bit compilation and GNU Binutils (`as`, `ld`, `objcopy`, `nm`):

```bash
python3 verify_november1_sources.py \
  --package 'build-november1/Forceware 382.69' \
  --out source-check-november1
```

This compiles six added runtime blocks, including retained predecessors, and compares their bytes at the final driver locations. It validates the implementation, not physical compatibility with every GPU.

## GP107/GP108 runtime corrections

Successful curve replies now provide the acknowledgement required by the legacy completion callback. The allocator reserves firmware workspace in addition to the 16-byte RPC body: 784 bytes for curve operations, 16/32/80 for the three admitted performance SET classes and 32/48/64 for the three power-management SET classes. Allocation failures, payload lengths and real firmware errors remain unchanged; unsupported request shapes retain their existing path.

Reset cleanup skips the callback of an already-canceled request while retaining native payload and sequence cleanup. This avoids calling a released translation context after a timeout followed by reset. The guard uses the current adapter and shared 391.35 provider, preserving other GPU families and request states.

Legacy PSI version 10/20 startup now maps the actual cached BIOS controller and voltage-domain information into the required global, rail and controller sequence. Runtime current selection maps logic/SRAM currents to the matching legacy rail. Invalid formats, selectors and transport failures retain their errors; version 30 MONO/SPLIT support is not implemented.

Implementation: [workspace.c](../sources/november1/workspace.c), [curve-ack.s](../sources/november1/curve-ack.s), [pmu-reset.s](../sources/november1/pmu-reset.s), [psi-current.c](../sources/november1/psi-current.c) and [psi-startup.c](../sources/november1/psi-startup.c). The [compiled-block manifest](../sources/november1/blocks.json) records their exact link addresses and compiler options. Prior routines retained in the image are included for byte verification; active hook targets are defined by the stock-to-release manifest.

## Package and qualification

The November 1 build continues October 31's firmware, native PMU worker ownership, GT 1030 DDR4 handling, voltage-boost controls, display and scaling policy, rendering/compute fixes, legacy-GPU boot repair and complete stock 368.81 INF set. It does not restore the superseded receive-owner or transfer wrappers. See the [October 31 guide](REBUILDING-10-31.md) for those retained changes and the [October 19 guide](REBUILDING-10-19.md) for its historical recipe.

Executable CPU comparisons cover workspace boundaries, acknowledgements, cancellation/reset ordering, adapter/provider guards and PSI command serialization, including preserved real-ROM inputs. The full November 1 installer was clean-installed and rebooted on a GTX 1050 Ti; installed hashes and loaded patch bytes matched. Checked Direct3D/OpenGL rendering, application exit/relaunch, OpenCL work and CUDA context operations passed on the functional baseline. CUDA context checks are not a CUDA kernel-execution claim. GP108 shares the corrected guards and CPU contracts; this revision's physical testing was on GP107.

The Witcher opening movie completed at 3440x1440 with working monitor audio and NVIDIA fixed-aspect scaling during bounded testing. A directly observed quiet replay did not reproduce a major freeze; small stutters and the earlier freeze remain unresolved. These results do not establish a general freeze cure, all-board compatibility or long-run stability.

Established display-component build fields and INF dates identify November 1. The intentionally original DisplayDriverExt.dll and unchanged HD Audio, PhysX, nView and other vendor-component versions remain preserved. Final release packaging changes only build notes and package checksums from the tested installer; every installation/runtime file is identical.

When upgrading, choose **Custom (Advanced) → Perform a clean installation**, then restart. Preserve a working installer; use Safe Mode and a clean installation to roll back if necessary.

## Earlier recipes and licensing

The current entry point is **rebuild_november1.py**, starting directly from stock 368.81 and the pinned vendor modules above. No previous project installer is required. Historical recipes retain their original inputs and hashes.

Project code and documentation retain the repository's GPLv3 and NVIDIA integration-exception terms. NVIDIA binaries and firmware retain their existing terms.
