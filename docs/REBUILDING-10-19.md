# Rebuilding Forceware 382.69

This guide describes the **10-19-2026 stable release**. **382.69 is this project's custom version number**, based on NVIDIA 368.81 for Windows XP 32-bit.

## Reconstruct the current release

The tested current route starts with the exact published October 17 installer and applies the October 19 changes. This preserves the complete inherited GP108, Pascal-only PMU/power, display, installer and stock-INF work without reapplying an older firmware experiment.

Download [Forceware 382.69 (10-17-2026)](https://github.com/SupraGSX/Forceware-382.69/releases/download/382.69-2026-10-17/Forceware.382.69.10-17-2026.exe). Required SHA-256:

```text
5c0cbd319641aba4eb2a5854fdbb8c654633999840ba7cf01d503358016f9413
```

Use the current repository files, Python 3.9+ and `7z`:

```bash
python3 rebuild_october19.py \
  --base-installer inputs/Forceware.382.69.10-17-2026.exe \
  --out build-october19
```

The output directory must not already exist. The program does not execute or install either driver. It validates the complete base package and nested Control Panel inventories, checks every original byte and resulting file hash, rebuilds both archives, then extracts and verifies the final installers.

Outputs include `Forceware 382.69 (10-19-2026).exe`, the extracted `Forceware 382.69/` directory, and `rebuild-result.json`. The tested reconstruction matched **633 non-generated outer files and all 469 Control Panel files**. The regenerated Control Panel archive and `SHA256SUMS.txt` are verified separately. With the recorded 7-Zip environment, the full installer also matched the published EXE hash; other compression versions may change archive bytes while preserving the exact runtime files.

| Published file | SHA-256 |
|---|---|
| October 19 EXE | `e3fc9dc564e0d5dcf2967cf4065ec4d21c5818041ac5554ef98032fa61fe3fe2` |
| `Display.Driver/nv4_mini.sys` | `9471ff8025e2f031d017b3e818dd5aa51ab267670e1ba7b2e96f329e0d805145` |

The [October 19 manifest](../sources/october19/manifest.json) records every input/output hash and guarded delta, including display build metadata and package text. It contains no complete NVIDIA driver image. The release tag points to the earlier public source commit; this reconstruction and guide were added afterward, so use current `main` for the October 19 recipe.

## What changed in October 19

### Legacy-GPU boot repair

Two injected hooks covered native alternate-entry targets. Architecture guards in their main entry paths did not protect branches arriving inside the overwritten instructions.

- The transfer epilogue restored the native call and the alternate entry at preferred VA `0x5C7FA8`. New stub entry `0xF09EC0` retains the Pascal transfer adapter from the safe preceding instruction boundary.
- The display-interrupt hook reroutes the native branch at `0x667F55` through `0xF09ED0`, replaying its displaced instruction before continuing at `0x668145`.

The original October 12 driver reproduced `0x7E` on a single primary GK107 GT 640. The exception followed an `ICEBP` byte reached inside the overwritten transfer-hook jump. The repaired Candidate2 passed full installation, reboot, cold start, GDI, Direct3D9 and OpenGL readback/relaunch checks on that card. GTX 760 and Quadro K620 require their own hardware qualification; this result does not resolve a separate secondary-card Code 10 report.

### GT 1030 fan-table compatibility

The GP108 fan upload serializer accepted device type 1 but rejected native-supported type 2 before submission. The correction accepts both device types while retaining type-1-only controllers, original XP object callbacks, 64-byte device records, 96-byte controller records, bounds checks, partial output and real error propagation. Transport, channel selection and firmware are unchanged.

Readable source: [fan-serialize.c](../sources/october19/fan-serialize.c). The installed hook is at preferred VA `0xEBDF60`, targeting `0xF09EE0`. Native XP and supported 382.23 type-2 serializers produced identical records in 128 executable differential cases. The exact final miniport passed 240 boundary/error/ABI/relocation cases. ROM-based parser tests identify a concrete compatibility defect; they do not establish that every reported GT 1030 artifact or Code 10 is resolved.

## Inherited behavior and scope

- **Core GPU handling:** October 17's Pascal-only PMU ownership/port serialization, clock/power and completion corrections remain intact. Fermi, Kepler and Maxwell retain native core handling, alongside deliberately shared display and Control Panel fixes.
- **GT 1030:** retains its existing GP108 firmware descriptors, host-protocol translations, clocks/power handling and completion fixes. Support is advertised specifically for GT 1030, not the whole GP108 product range.
- **Display:** retains the preceding DisplayPort bandwidth/training/depth/scaling and HDMI identification/SCDC/audio/scaling policy. The separate High Clock experiments are not included.
- **Firmware:** unchanged from the October 17 package. The later P620/391.35 consolidation is a separate private experiment and is not part of this stable release.
- **Installation:** retains the selected original installer extension, existing HD Audio/PhysX/nView versions, XP/Server 2003 x86 handling and component visibility corrections. All stock 368.81 INF files and device entries, including notebook/OEM entries, remain present.
- **Build identification:** modified display components use October 19 metadata. The intentionally original installer extension and unchanged vendor-component dates are retained.

## Validation and rollback

When upgrading, choose **Custom (Advanced) → Perform a clean installation**, then restart. Verify the installed display files against the manifest before interpreting a result. Keep the preceding working installer for Safe Mode rollback.

The final combined October 19 package has exact reconstruction/extraction verification and executable final-miniport checks. The Candidate2 parent has the GT 640 hardware validation described above; the combined dated installer and fan-type-2 boards have not received their own complete hardware installation qualification. A working MSI GDDR5 GT 1030 control does not qualify every Gigabyte/Colourful board or DDR4 model. P620 Code 10, intermittent physical MMU/FIFO/0xEA reports and broad long-run stability remain separate investigations.

For GPU VM testing, make the passed-through card primary (`x-vga=on`, no emulated VGA). Check physical output as well as API/rendered readback. Register programming alone does not prove a valid picture. No new individual-model validation is implied by an INF entry.

## Earlier reconstruction and implementation references

The original stock-368.81 reconstruction remains in [rebuild.py](../rebuild.py) with its historical [patches.json](../patches.json) and templates. Those files describe the October 11 recipe and must not be presented as an exact October 19 stock-to-release rebuild. Use the current incremental recipe above for October 19.

The [historical October 11 guide](REBUILDING-10-11.md) retains the detailed subsystem analysis, Windows addresses, exact donor hashes, and pinned Nouveau/Mesa references. Its donor selections and output hashes are historical. Follow its original links from the repository root, or view that guide in the October 11 tag. Linux structures and callbacks were research guides; Windows ABIs and firmware protocols were established independently. Signed firmware remains intact.

Project code/documentation retain the repository's GPLv3 and NVIDIA integration-exception terms; NVIDIA binaries and firmware retain their existing terms.
