# Rebuilding Forceware 382.69

This guide covers **November 9, 2026**. **382.69 is the project's custom version number**, based on NVIDIA 368.81 for Windows XP 32-bit. The build starts directly from stock 368.81 and the pinned vendor firmware modules below; no previous Forceware installer is required.

## Inputs and build

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


The donors reconstruct all retained resources, including inactive earlier copies required for byte-exact reproduction. Final dispatch tables select the active firmware paths; GP107/GP108 use their current 391.35 integration.

Use Python 3.9+ and `7z`:

```bash
python3 rebuild_november9.py \
  --stock inputs/368.81-desktop-winxp-32bit-international.exe \
  --quadro inputs/quadro-376.84/nvlddmkm.sys \
  --geforce inputs/geforce-378.78/nvlddmkm.sys \
  --gp102 inputs/geforce-381.65/nvlddmkm.sys \
  --gp107 inputs/quadro-390.77/nvlddmkm.sys \
  --gp108 inputs/geforce-382.23/nvlddmkm.sys \
  --pascal391 inputs/geforce-391.35/nvlddmkm.sys \
  --out build-november9
```

The output directory must not exist. The builder checks all seven input hashes, complete stock package and Control Panel inventories, 130 donor resources, guarded stock-copy ranges and final patches/templates. It verifies every resulting payload hash, rebuilds both installers, and extracts them again. It does not install or execute a driver.

The [stock-to-release manifest](sources/november9/stock-manifest.json) accounts for all **638 outer package members and 469 Control Panel members**. Of the outer members, 636 are reconstructed directly; the Control Panel installer and checksum list are generated. Compression-tool differences can change archive bytes, but runtime and nested payload hashes must match.

The verified stock rebuild reproduced the complete November 9 release EXE byte-for-byte.

Outputs are `Forceware 382.69 (11-9-2026).exe`, the extracted `Forceware 382.69/` directory and `rebuild-result.json`.

| File | SHA-256 |
|---|---|
| November 9 EXE | `bb7ff231910851827143a7a090d0e4aca5715a2ce0f26294c8d1004ea40a00f9` |
| `Display.Driver/nv4_mini.sys` | `375884957ab5b4e72ae56b9feb1bc1865c30cf2ab1df80b2407cc0ded5ffc4f5` |
| `Display.Driver/nvapi.dll` | `39e8457527090affc1ac9f169718718d0d354b29c7ee484f4554113bb35d1d3e` |

For an independent compiled-byte check, install GCC with 32-bit compilation and GNU Binutils (`as`, `ld`, `objcopy`, `nm`):

```bash
python3 verify_november9_sources.py \
  --package 'build-november9/Forceware 382.69' \
  --out source-check-november9
```

This compiles the 15 added blocks retained since November 1 and checks their exact final bytes. The [block manifest](sources/november9/blocks.json) records source files, link addresses and compiler flags. Earlier recipes retain the sources for their own changes. The current stock manifest defines the final hooks, including the four-byte GP107 link-policy change, metadata and retained older code. Compiled-byte identity establishes reconstruction, not hardware compatibility.

## Runtime and display changes

The November 9 additions cover:

- **Power-policy serialization:** maps supported policy filters, event/violation associations and remaining stock policy classes to the firmware wire format. Values come from the owning XP objects and native serializers; unsupported shapes and real errors retain their failure behavior.
- **State and completion handling:** translates the owned display-state view in the conditional low-power copy/handoff path, preserves the fan controller's cooler index and BIOS memory-clock-residency setting, and derives the legacy bus acknowledgement from validated firmware status.
- **Initialization cleanup:** checks nullable extended-object allocation before zeroing, applies the supported GP108 memory-power feature mask, and releases the added shared surface after acknowledged PMU detach on the admitted late startup-failure path. The original initialization error remains intact.
- **DisplayPort and timing enumeration:** admits HBR3 for GP107 while retaining actual training, receiver checks and bandwidth/depth fallback. The bounded primary EDID extension adds supported progressive CTA timings through VIC 107 and DisplayID Type I timings while preserving native rows, downstream filtering and the original native result. It does not implement VIC 118, DSC, HDR or MST.
- **DDR4 GT 1030:** restores clock-drive and QUSE DLL programming, then writes the eight non-training write-barrel-shifter registers from the selected timing context. The two surrounding one-microsecond waits are non-flushing. Guards require the owning GP108 DDR4 path; the barrel-shifter adapter admits the supported single-partition layout and skips the non-training sequence when write training is enabled.

Implementation files are grouped under [sources/november9](sources/november9/). Existing November 1 request-workspace, completion, PSI, reset and native PMU worker ownership corrections remain in the build. No superseded receive-owner or transfer wrappers are reinstated. The [November 1 guide](docs/REBUILDING-11-1.md) and [October 31 guide](docs/REBUILDING-10-31.md) describe the retained integrations; their hashes and limitations describe those historical builds.

## Validation and limits

- The DDR4 GT 1030 repair passed native-instruction CPU comparisons, adapter/fallback guards and preferred/relocated stack/register checks. The full November 9 installer clean-installed and rebooted on the physical passthrough card at 3440×1440 over HDMI. Six installed binary hashes and 40 loaded code spans matched; six GDI/Direct3D/OpenGL rendering/relaunch cycles passed checked results, with no native bugcheck in the bounded observation. The picture was confirmed normal and full-width.
- GDDR5 GT 1030 testing covered the preceding runtime baseline's full installation, rendering, CUDA/OpenCL checked results, targeted failed-start detach/release and subsequent normal cold startup. The release also has user-reported hardware validation on M4000, GTX 1050 Ti, GT 640 and both GT 1030 memory variants; individual test durations were not specified.
- The included GP107 link policy was physically confirmed at 3440×1440/175 Hz, HBR3 ×4, RGB 8-bit on GTX 1050 Ti. HDMI was confirmed at 543.5 MHz on Pascal and 319.75 MHz on GT 640. These results do not establish every board, cable, adapter, monitor or exact policy ceiling.
- The latest package has not been requalified on P620; other untested models and memory topologies remain unconfirmed. Conditional low-power paths have CPU coverage where their physical triggering was unavailable. Long-run MMU/FIFO/timeout stability and every previously reported freeze remain broader qualification limits.

The release package differs from the tested November 9 installer only in documentation and its regenerated checksum list; every installation/runtime file is identical. Established display build fields and INF dates identify November 9. The intentionally stock DisplayDriverExt.dll and unchanged vendor component versions remain preserved.

When upgrading, select **Custom (Advanced) → Perform a clean installation**, then restart. Preserve a working installer; use Safe Mode and a clean installation to roll back if necessary.

## Earlier recipes and licensing

Historical rebuild scripts retain their original inputs and hashes. Use **rebuild_november9.py** for this release; it starts from stock 368.81.

Project code and documentation retain the repository's GPLv3 and NVIDIA integration-exception terms. NVIDIA binaries and firmware retain their existing terms.
