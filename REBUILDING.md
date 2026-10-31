# Rebuilding Forceware 382.69

This guide covers the **October 31, 2026 build**. **382.69 is the project's custom version number**, based on NVIDIA 368.81 for Windows XP 32-bit. The [October 19 stable reconstruction](docs/REBUILDING-10-19.md) remains available with its original inputs and hashes.

## Reconstruct October 31

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
python3 rebuild_october31.py \
  --stock inputs/368.81-desktop-winxp-32bit-international.exe \
  --quadro inputs/quadro-376.84/nvlddmkm.sys \
  --geforce inputs/geforce-378.78/nvlddmkm.sys \
  --gp102 inputs/geforce-381.65/nvlddmkm.sys \
  --gp107 inputs/quadro-390.77/nvlddmkm.sys \
  --gp108 inputs/geforce-382.23/nvlddmkm.sys \
  --pascal391 inputs/geforce-391.35/nvlddmkm.sys \
  --out build-october31
```

The output directory must not exist. The builder validates all seven input hashes and the complete stock package/Control Panel inventories, expands the required stock files, extracts and hashes 130 donor resources, copies guarded stock data ranges and applies all final patches/templates. It then checks every resulting payload hash, rebuilds both installers and extracts them again for verification. It does not install or execute the driver.

Outputs include `Forceware 382.69 (10-31-2026).exe`, the extracted `Forceware 382.69/` directory and `rebuild-result.json`. The [stock-to-release manifest](sources/october31/stock-manifest.json) records every input/output hash, donor descriptor, stock-copy range, patch boundary and final package member. The tested recipe reproduced the final EXE byte-for-byte, including **636 non-generated package files and all 469 Control Panel files**. Compression-tool differences can change archive bytes; all runtime files and Control Panel members must still match exactly.

| File | SHA-256 |
|---|---|
| October 31 EXE | `e176dc2ed168bf57f1e73dffe0dc028a055f811d7b98a2d507095e40130d6531` |
| `Display.Driver/nv4_mini.sys` | `e6a1ac13a399ada67865e89ab051ac912578c4bc1ea37df1ce6a5daa911cc57d` |
| `Display.Driver/nvapi.dll` | `878f8dd846e1103c02e695aad365a032daad23c1c1a0283b6d33ed5b129bb41a` |

For an independent compiled-byte check, use GNU Binutils (`as`, `ld`, `objcopy`, `nm`):

```bash
python3 verify_october31_sources.py \
  --package 'build-october31/Forceware 382.69' \
  --out source-check-october31
```

This assembles all three new adapters and compares their bytes at the final driver locations. It validates the implementation, not physical compatibility with every GPU.

## Changes from October 26

### Pascal PMU synchronization

The asynchronous VFE worker could enter PMU work without owning the native resource-manager semaphore. The corrected worker acquires that semaphore before GPU lookup or object access, retains the native state checks and fetch operation, and releases ownership on all successful-acquisition exits. Failed acquisition preserves the native result; missing or unloaded objects skip work without leaking ownership.

The callback selector at preferred VA `0x772EE9` uses the current adapter's architecture and implementation: Pascal `0x130`, implementations 2, 4, 6, 7 and 8. Other adapters keep their original worker. The new worker starts at `0x1072BB1`; there is no machine-global Pascal-present flag.

The earlier receive-owner/pending-service and Falcon-transfer wrappers are replaced by this native worker-ownership repair. Eleven entry/release sites return to stock instructions, including the safely relocated transfer epilogue. The corrected legacy alternate-entry landing and separate display-interrupt branch repair remain intact. Existing firmware translations, scratch allocation, clock/power adaptations and display handling are preserved.

Implementation: [worker.s](sources/october31/worker.s), 270 bytes including the selector. Executable tests cover adapter selection, semaphore contention, missing/reset objects, native failure propagation, stack/register contracts and relocated operation. Bounded 2-CPU and 32-CPU GPU-passthrough tests observed ownership before fetch and completed the concurrent PMU workload without a recorder trigger. This does not establish that every historical MMU/FIFO or `0xEA` report is resolved.

### GT 1030 DDR4 memory handling

Three adapters correct the GP108 DDR4 path while preserving GDDR5 and nonmatching GPUs:

- `0x645F40`: reconstruct the seven-bit memory reference-voltage value from the existing decoded fields and apply it to MRS6 after successful native timing generation.
- `0x6A8BEB`: emit the DDR4 digital-DLL calibration sequence with the existing XP register, script and MMIO callbacks, preserving write order, masks and the 10-microsecond delay.
- `0x6FCC05`: retain the periodic-calibration request from a successfully decoded memory-clock record.

Each adapter checks the actual GPU and memory type; a PCI ID or ROM filename does not force DDR4 handling. Existing errors, partition selection and calibration admission remain in effect. [ddr4.s](sources/october31/ddr4.s) assembles to 652 bytes. Executable comparisons against the supported 391.35 driver covered all VREF values, periodic/one-shot calibration, parser boundaries, real-ROM records, errors and nonmatching controls. **Physical DDR4 GT 1030 validation remains pending.**

### XP voltage-boost controls

Four NVAPI voltage-control admission calls previously rejected XP before reaching the native GPU request. The adapter preserves the original operating-system predicate, then admits GP107/GP108 only after a successful architecture query for the actual GPU handle. Other GPUs, unknown handles and query failures retain the original denial.

The calls are at DLL RVAs `0x130125`, `0x130525`, `0x12B6BB` and `0x12BBCB`; the 89-byte [voltage.s](sources/october31/voltage.s) adapter is at RVA `0x353000`. Native version, pointer and range checks, firmware replies and voltage-policy limits remain unchanged. The 0–100% control adjusts **voltage-boost allowance**, not a forced millivolt setting.

On GTX 1050 Ti, MSI Afterburner exposed the control and completed apply, independent native readback and restore at idle and under checked load. Invalid-version, null-buffer and out-of-range calls retained their errors. GP108 uses the same guarded admission, but its physical voltage-control test remains pending.

## Package and validation

October 31 keeps the October 26 GP107/GP108 391.35 firmware and protocol work, HDMI/DisplayPort policy, rendering/compute fixes, legacy boot repair, GT 1030 fan-table correction and complete stock 368.81 INF set. The DDR4 changes do not replace the GDDR5 path. Earlier-family core handling remains native except for deliberately shared display/Control Panel fixes and the preserved legacy branch repair.

Established display-component build fields and INF dates identify October 31. The intentionally original `DisplayDriverExt.dll` and unchanged HD Audio, PhysX, nView and other vendor-component versions remain as before.

The final installer has the same installation/runtime payload as the clean-installed, rebooted GTX 1050 Ti test package. Final repackaging changes only labels, build notes and package checksums. Installed core-file hashes were verified, and Direct3D/OpenGL checked rendering, application exit/relaunch, OpenCL and Afterburner apply/restore tests passed. Temperature-transition query testing also passed within its recorded window; bounded tests do not establish universal stability. Broader physical-system, reset/sleep and additional-card qualification remains ongoing.

When upgrading, choose **Custom (Advanced) → Perform a clean installation**, then restart. Verify installed files against the manifest before interpreting a result. Preserve a working installer; use Safe Mode and a clean installation to roll back if necessary.

## Earlier recipes and licensing

Use [rebuild_october19.py](rebuild_october19.py) with the [October 19 guide](docs/REBUILDING-10-19.md) for that stable build's incremental recipe. The original [rebuild.py](rebuild.py), [patches.json](patches.json) and [October 11 guide](docs/REBUILDING-10-11.md) describe their historical package. The current stock-to-October-31 entry point is **`rebuild_october31.py`** above; it needs no earlier project release.

Project code and documentation retain the repository's GPLv3 and NVIDIA integration-exception terms. NVIDIA binaries and firmware retain their existing terms.
