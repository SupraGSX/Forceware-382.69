# How Forceware 382.69 was built from NVIDIA 368.81 for Windows XP

Forceware 382.69 applies binary patches, selected firmware resources and installer changes to **NVIDIA 368.81 for Windows XP 32-bit**. **382.69 is this project's custom release number.** This guide describes the **10-3-26** update.

NVIDIA's proprietary source is unavailable; the supplied source consists of our Python patcher and C/assembly routines. This guide explains the final implementation and how to reproduce it.

The changes enable the tested Pascal P4000/GTX 1080 Ti configurations, expand desktop INF coverage, add DisplayPort HBR3 and depth negotiation, correct HDMI handling, and restore Control Panel functions.

## 1. What can be reproduced with this directory

| File | Purpose |
|---|---|
| [rebuild.py](rebuild.py) | Reconstructs the package from the exact stock installer and two supplied firmware-donor modules. |
| [patches.json](patches.json) | Input hashes, output hashes, byte guards, edits, firmware extraction instructions and the complete package/CPL file inventory. |
| [sources/](sources/) | Readable C/assembly for the added routines, link scripts and the NVAPI version-reporting patch generator. |
| [verify_sources.py](verify_sources.py) | Compiles 16 code blocks and compares their bytes with the reconstructed driver. |
| [templates/](templates/) | Final INF, installer configuration and text files used during reconstruction. |
| [desktop-gpus.json](desktop-gpus.json) | All 50 Maxwell/Pascal desktop INF records, including subsystem-qualified OEM entries. |

The manifest applies the final changes directly to the exact vendor inputs.

A verified rebuild matched **582 outer-package files and all 469 Control Panel files byte-for-byte**. The remaining two outer files are the regenerated Control Panel archive and `SHA256SUMS.txt`. Both archives passed extraction checks; all 16 compiled source blocks matched the released instructions.

Compression, timestamps and tool versions can change archive hashes while preserving identical driver files. The reproduction check is the exact extracted payload.

## 2. Rebuild instructions

### 2.1 Obtain the exact original inputs

Use the **32-bit international** packages. An x64 module or a different release is not an interchangeable donor.

1. [NVIDIA 368.81 Windows XP 32-bit international](https://us.download.nvidia.com/Windows/368.81/368.81-desktop-winxp-32bit-international.exe): the full base installer.
2. [Quadro 376.84 Windows 7/8 x86 international](https://us.download.nvidia.com/Windows/Quadro_Certified/376.84/376.84-quadro-grid-desktop-notebook-win8-win7-32bit-international-whql.exe): supplies the ACR and SEC2 resources. NVIDIA lists the P4000 among this release's supported additions. [Official release information](https://www.nvidia.com/download/driverresults.aspx/115308/en-us/).
3. [GeForce 378.78 Windows 7/8 x86 international](https://us.download.nvidia.com/Windows/378.78/378.78-desktop-win8-win7-32bit-international-whql.exe): supplies the VPR resources.

The firmware donors are their **expanded `Display.Driver/nvlddmkm.sys` files**, not the entire Windows 7 driver stacks. Extract their installers with 7-Zip. If the driver is stored as `nvlddmkm.sy_`, extract that CAB member again to obtain `nvlddmkm.sys`. Keep the two identically named donor modules in separate directories. No donor installation or execution is necessary.

Required SHA-256 values:

| Input | SHA-256 |
|---|---|
| Full stock XP 368.81 EXE | `eaaef0650b6c6a99a2ed70d5e15aaf5221570ae596ca51784ff5e6fc7e5482f1` |
| Expanded Quadro 376.84 `nvlddmkm.sys` | `84fcd8f31466956f40f1aebc833ef4b23c30b0077e61a842257b4076e4482633` |
| Expanded GeForce 378.78 `nvlddmkm.sys` | `467bdc2e47f4f36330ed011520b9ac79e3051c20728a60e5a2ecebda0228152f` |

The builder rejects incorrect input hashes. NVIDIA components retain their applicable licenses.

### 2.2 Run the builder

Use Python 3.9 or newer and a `7z` command. The tested environment was Linux with Python 3.12 and 7-Zip.

From this directory, with the inputs arranged as shown:

```bash
python3 rebuild.py \
  --stock inputs/368.81-desktop-winxp-32bit-international.exe \
  --quadro inputs/quadro-376.84/nvlddmkm.sys \
  --geforce inputs/geforce-378.78/nvlddmkm.sys \
  --out build-38269
```

The output directory must not already exist. The program first validates all three input hashes, then:

1. Extracts the original full installer and its nested Control Panel installer.
2. Expands the compressed display modules needed by the final package.
3. Extracts 15 precisely identified firmware/resource records from the supplied donors and validates every decoded payload hash.
4. Applies the final byte edits, checking original bytes and expected output hashes.
5. Writes the final INF/configuration files and preserves the selected original components.
6. Rebuilds the nested Control Panel SFX with the original XP-compatible launcher.
7. Generates package checksums and builds the full outer SFX.
8. Extracts both rebuilt archives again and verifies their contents.

Outputs include:

```text
build-38269/
  Forceware 382.69.exe
  Forceware 382.69/
  rebuild-result.json
  work/
```

`rebuild-result.json` should report 584 package files, 582 exact release-file matches, 469 exact Control Panel member matches, and successful extraction checks. Scratch files and compiler outputs belong under the build directory; they are not installed by the driver.

### 2.3 Optionally rebuild the added machine code from source

The byte-replay builder does not compile C. For an independent check of the readable source, install/use GNU `as`, `ld`, `objcopy`, and GCC with freestanding `-m32` compilation support. The successful comparison used GCC 13.3.0 and GNU Binutils 2.42.

```bash
python3 verify_sources.py \
  --package "build-38269/Forceware 382.69" \
  --cpl build-38269/work/cpl \
  --out source-check
```

This checks 16 compiled blocks at their locations in the rebuilt PE files, including the inactive HDMI bridge retained in the final image.

Other compiler versions may emit different instructions; investigate mismatches before substituting them. The manifest defines the tested binary result.

### 2.4 Install and validate separately

Run the outer EXE and use the normal NVIDIA installer, or run `setup.exe` from the extracted folder. Restart. These are modified display files; original NVIDIA catalog signatures no longer authenticate the modified payload.

For QEMU testing, make the passed-through GPU the guest's primary VGA device. The tested configuration used `x-vga=on` with no emulated VGA.

Validate installation and rendering before high-bandwidth modes, following section 12.

## 3. Existing Pascal support in 368.81

XP 368.81 already contains substantial Pascal hardware and graphics-class support. Miniport routines at preferred VAs `0x6010F0`, `0x6F8A60` and `0x600EC0` correspond to Pascal page-pool, GPC/PES-mask and attribute-buffer operations. The display DLL recognizes graphics class `0xC197` and a Pascal channel-class path.

The patches connect and correct this implementation. Windows 7 binaries supply selected firmware resources; XP retains its own operating-system interfaces and rendering/compiler machinery. Descriptive internal names here are inferred from disassembly and behavior, rather than NVIDIA source symbols.

## 4. Expose the existing Pascal display paths

In `nv4_disp.dll`, the class-selection logic failed to handle Pascal capability bit `0x80000`, preventing the required display objects from being allocated.

Two changes repaired this:

1. At preferred VA `0xB4E1E`, branch to a 51-byte stub at `0x29FDC5`. When bit `0x80000` is present, prepare the existing root-allocation arguments and select class `0x9870`, continuing through the original allocation path. For other GPUs, replay the displaced instructions and return to the stock selection chain.
2. At `0xB6FBF`, expand an existing base-channel selection mask from `0x600000` to `0x680000`. This adds the same Pascal display bit to the existing `0x927C` path. The original allocation and error handling remain in use.

The allocated objects use the existing XP acceleration path. Source: [display-root.s](sources/display-root.s); the manifest contains the mask and PE edits.

The GP100 bit was not added. GP100, GP107 and GP108 are excluded from the current INF.

## 5. GP102 required a coherent firmware/host-interface repair

GP102 additionally requires compatible ACR, VPR and SEC2 resources and a host-side boot-descriptor adapter.

### 5.1 Replace the selected ACR resource set

The failing path reached the selected authenticated-loader firmware and returned raw status `0x23`. Disassembly of that selected firmware identified a version comparison: the target GP102 required version 3, while the XP-selected firmware classified it as version 2.

Six complete ACR resources were taken from the exact Quadro 376.84 x86 miniport. These include the payload and its associated header/signature metadata. Compressed donor records were decoded, checked, appended to the XP image and referenced through the existing XP resource descriptors. Resource IDs were `0x1AC`, `0x1AE`, `0x1B0`, `0x1B2`, `0x1B4` and `0x1B6`.

The 16,384-byte ACR payload has SHA-256:

```text
cd7af91422cccf09eff250040e70d3f48430cfe7c07d7130efd82ee88c085b3c
```

This removed the observed version failure without patching the firmware's validation result or altering its signed instructions.

### 5.2 Replace the matched VPR resources

The matched VPR resources establish the protected-memory-region state expected by the XP verifier.

The working approach copied the complete matched VPR set from GeForce 378.78 x86: a 3,328-byte image, 40-byte header, production and debug signature records, signature location and signature index. Six existing resource-address operands at `0x6DE9B1` through `0x6DE9D3` were redirected. Their existing relocation entries were preserved.

The VPR image hash is:

```text
6b977b60ebfe5023b6f29a90f6faf28b69f69f15e76fae3bc4d2f061cb59520a
```

The existing verifier and permission checks remain active.

### 5.3 Use a matched SEC2 tuple

Use this matched Quadro 376.84 SEC2 tuple:

| Resource | Decoded length | Donor descriptor VA |
|---|---:|---:|
| SEC2 image | 203,776 bytes | `0x698624` |
| SEC2 descriptor | 656 bytes | `0x69863C` |
| SEC2 signature | 192 bytes | `0x698660` |

The image hash is `24fc5122aaf36722987ffc74b04d55ba476e62a72565c654d87406ed36148625`. Associated descriptor and signature hashes are recorded in `patches.json`.

The final firmware combination is **ACR 376.84 + VPR 378.78 + SEC2 376.84**.

### 5.4 Adapt the SEC2 boot descriptor at the correct boundary

The host and SEC2 bootloader use different descriptor layouts:

- The XP host constructed a 56-byte `loader_config_v1`-shaped descriptor.
- The selected newer bootloader expected an 84-byte `flcn_bl_dmem_desc_v2`-shaped descriptor.
- The original embedded host buffer was only 76 bytes. Enlarging it in place would overwrite neighboring state.
- The final WPR destination already reserved 256 bytes, sufficient for the new descriptor.

The solution was a **198-byte host-side adapter** at preferred VA `0xD06920`, called instead of the existing final-copy call at `0x7271E3`. It builds an 84-byte temporary stack descriptor, maps the DMA/code/data/entry/argument fields to the expected positions, and invokes the existing copy function `0x470D10`.

The adapter only activates when all observed compatibility guards match: Falcon ID 7, old copy length `0x38`, destination reservation `0x100`, firmware build `0x014A7C8C` and boot entry `0xFD00`. Otherwise it follows the original copy path. The signed firmware and original embedded host structure remain intact.

Source: [sec2-bootdesc.S](sources/sec2-bootdesc.S). Tests verified field placement, boundary protection, register/stack preservation, guard fallbacks and all 84 uploaded bytes. SEC2 queues and adapter initialization completed, allowing hardware D3D9/Shader Model 3 testing.

## 6. Topology and EDID management required two separate changes

- In `nvWsS.dll`, a guarded replacement for the local workstation-status predicate at preferred VA `0x1011658B` supplies the status expected by that UI path. The stub is at `0x10257FE7`; its source is [topology-predicate.s](sources/topology-predicate.s). This changes the Control Panel's workstation query, not the GPU's actual PCI identity or every product-class restriction in the driver.
- In `nv4_disp.dll`, a branch displacement byte at **file offset** `0x19947` changes from `0x0A` to `0x1B`, allowing the GeForce product-class case through the existing SetEDID path. Other validation remains.

Both changes are installed with the driver. UI visibility and EDID operations were tested separately.

## 7. DisplayPort: negotiate the link, then choose a compatible output depth

### 7.1 Accept the higher rate codes

At display DLL VA `0x48280`, XP's wrapper accepted rate codes 6 and 10, corresponding to RBR/HBR, but substituted the current value for codes 20/30. Consequently an API request could return success without actually changing the link rate.

The new 24-byte stub at `0x356600` admits codes 20 and 30 while preserving the existing behavior for other values. The source is [dp-api-rate.s](sources/dp-api-rate.s).

### 7.2 Select full link training

The miniport must also select full training for HBR2/HBR3.

The patch at miniport VA `0x44DFF4` routes HBR2/HBR3 through the existing full-training implementation. Its 20-byte stub is at `0x89B86A`; see [dp-full-training.s](sources/dp-full-training.s). The existing Pascal rate setter already understood these rates.

### 7.3 Read extended receiver capabilities

The XP code originally read 12 bytes of base DPCD data. It therefore missed the extended-capability flag at `0x0E`. The tested receiver advertised HBR2 in its base block, but HBR3 in its extended block at `0x2200`.

The updated path reads 15 bytes, checks the flag, and conditionally reads and validates the extended block before calling the original parser. Failed or invalid extended reads retain the base capabilities. The 126-byte stub is at `0xD06A00`; see [dp-extended-caps.s](sources/dp-extended-caps.s).

### 7.4 Extend automatic training choices

The automatic configuration table contained six RBR/HBR lane/rate combinations. The final table preserves those six entries and adds **HBR2 ×4 and HBR3 ×4**. Six existing relocated table pointers are updated, the scan length changes from 72 to 96 bytes, and the default preference value changes from `0x654321` to `0x65432178`.

Capacity follows successful training. Higher-rate one- and two-lane automatic entries were not added; the unsafe guessed-link fallbacks are removed as described below.

### 7.5 Select a matched trained link and validate depth

Miniport hook `0x44C737` reads the successful-training bitmap at output+`0x2D00`, bounds it by receiver limits, and returns the highest-capacity **matched rate/lane pair**. Empty results return 0/0. The display selector at `0x47E50` validates that pair instead of guessing another configuration.

Miniport candidate-mode calculations at `0x443D49` and `0x457EEE` use at most 8 bits per color for admission. Actual mode selection at display VA `0x492A9` retains the requested depth when it fits; higher depths fall back to 8 bits when that fits, otherwise the mode fails. The calculation retains 8b/10b coding and the existing 0.5% clock margin. Unknown depth codes and arithmetic overflow fail closed.

Hooks at `0x492E5` and `0x4A0E8` remove the old guessed-link fallbacks. The existing hardware training/error paths remain in use. A previously successful probe cannot guarantee a changed cable or receiver will retrain.

Source: [dp-policy.c](sources/dp-trained/dp-policy.c), [miniport adapter](sources/dp-trained/mini-hooks.s), [display adapters](sources/dp-trained/disp-hooks.s). Detailed policy: [DisplayPort update](templates/package/Documentation/DisplayPort-update.md).

GTX 980 Ti tests confirmed normal native 3440x1440/100 on HBR2 x4 with RGB10, native 60 Hz on restricted HBR x4 with automatic RGB8 fallback, and 1080p on restricted RBR x4 with RGB10. Over-budget timings were rejected. These tests exercise real lower link rates, not a separate older DP1.1 GPU.

## 8. Correct Control Panel classification, Customize and scaling

The older Control Panel treated output bits 8–15 as analog TV. The 368.81 driver placed a digital DisplayPort output in that range, so the UI misclassified a PC display and restricted Customize. The 355.98 comparison used a different bit position for the same connection.

The current `nvcpl.dll` patches central mask/type/index conversions to interpret bits 0–7 as CRT and bits 8–31 as digital outputs. The earlier Customize-only bypass in `nvDispS.dll` is removed; the original eligibility predicate now receives the corrected classification.

A second DFP mask at `nvcpl.dll` VA `0x10119EA7` changes from `FFFF0000` to `FFFFFF00`. This allows the scaling-cache refresh to run for the current output, so fixed-aspect settings persist after Apply, reopening the panel and rebooting. Custom-mode create/test/save/delete and scaling/no-scaling selection were exercised on DisplayPort. This does not establish every monitor or differing-aspect black-bar geometry.

The exact guarded edits are in `patches.json`; this is a targeted repair of the observed conversions, not a global replacement of every similar constant.

## 9. HDMI identification, SCDC and clock policy

### 9.1 Preserve HDMI identity

A legacy EDID summary stored successive vendor blocks in one slot. An HDMI Forum block, OUI `0xC45DD8`, could overwrite the legacy HDMI OUI `0x000C03`, causing the driver to report a non-HDMI connection.

The 55-byte routine at miniport VA `0x8742B0` skips Forum blocks only in that legacy summary, along with blocks too short to contain an OUI. Raw EDID data and the separate capability parser remain intact. Source: [hdmi-vendor-summary.s](sources/hdmi-vendor-summary.s).

### 9.2 Apply the HDMI/DVI policy

In the display DLL, the patch at `0x4111F` queries HDMI status. A positive GPU/output-and-sink HDMI result retains single-link TMDS behavior; other connections retain the original 165-MHz DVI comparison.

The miniport extension is limited to GM200/GM204/GM206 and GP102/GP104/GP106/GP107 on the digital TMDS/SOR path. GP107 remains in that internal family check but is excluded from the installable INF. Its chosen ceiling is **594 MHz for the tested RGB8 path**, bounded by:

- Valid digital EDID, checksum/bounds checks and legacy HDMI identity.
- Sink-advertised TMDS limits and source/board/resource-manager restrictions.
- SCDC and advertised high-rate capability for clocks above 340 MHz.
- A refreshed source query; failed or empty queries clamp conservatively instead of retaining a previous sink's elevated limit.

The shared default at `0x5BD79B` remains **165,000 kHz**, and the scrambling/high-clock-ratio transition remains 340,000 kHz. The project's 594-MHz ceiling is an implementation choice, not HDMI 2.0's universal maximum.

Sources: [hdmi-policy.c](sources/hdmi-policy.c), [hdmi-hooks.s](sources/hdmi-hooks.s), [hdmi-protocol.s](sources/hdmi-protocol.s).

### 9.3 Pass capabilities and update cached limits

Hooks at `0x4567A6` and `0x45889E` refresh the policy around mode validation and EDID processing. A hook at `0x79C57A` handles the extension after the original handler resolves and class-checks the connector. The display DLL and miniport form a matched pair.

Capabilities pass through control `0x00730293` with marker `0xA0000000`; existing low capability bits retain their meanings and unmarked requests retain stock behavior. A subsequent `0x0073028A` query returns the resolved limit. The Windows cache uses 10-kHz units; the resource-manager limit uses kHz.

The driver uses its existing sink/SCDC and source-programming machinery. A 567-byte inactive capability bridge remains in the image and source verification; the active hooks use the final policy above.

### 9.4 Recover from failed high-rate setup

The display hook at `0x49681` arms a GPU/connector-specific transaction before a positively identified HDMI mode above 340 MHz. Private ARM/END commands are intercepted at miniport `0x79C502` before the existing capability setters. State occupies an owned 32-slot table, with generation tracking and a non-blocking atomic lock.

Miniport hook `0x6E3171` retries an armed SCDC setup write at most three times, with native 2 ms delays. A successful acknowledgement is latched. Later SCDC read failures do not invalidate an established link. Outside the transaction, the original single-write behavior remains.

Display cleanup at `0x49892` consumes the mode-local marker and transaction result; `0x4988D` preserves the marker on an existing failure edge. Hook `0x49C35` propagates failure into XP's mode-enable path. In injected-failure tests, XP selected safe 640x480 output before the test helper intervened. This is not restoration of the exact prior mode. NVAPI TryCustomDisplay can still report success when XP substitutes that safe mode; applications must inspect the actual mode.

Source: [recovery policy](sources/hdmi-recovery/scdc-recovery.c), [miniport hooks](sources/hdmi-recovery/scdc-mini.s), [display hooks](sources/hdmi-recovery/scdc-disp.s). The distributed build uses `FAULT=0`. See [HDMI recovery implementation](templates/package/Documentation/HDMI-SCDC-recovery.md).

SCDC availability is not equivalent to EDID readability or input selection. Later reads sometimes failed while the picture remained normal; the cause is unresolved. Hotplug, resume and alternate mode-update paths were not separately validated by these tests.

## 10. Build a normal full installer and expand the INF

The complete stock installer supplies setup, HD Audio, PhysX, nView and the other retained components.

The desktop INF work retained the selected legacy desktop entries and added/retained 50 Maxwell/Pascal records. Subsystem-qualified desktop OEM aliases are kept specific rather than broadly matching device IDs also used by mobile products. Mobile, GP100, GP107 and GP108 GPUs are excluded.

Additional models are listed in the [README](README.md); exact device and subsystem matches are in [desktop-gpus.json](desktop-gpus.json) and the [final INF](templates/package/Display.Driver/nv4_dispi.inf).

The installer was also adjusted to:

- Reference the expanded replacement files, removing competing compressed originals for those modules.
- Use the intended display INF rather than allowing another bundled INF to select an unintended model path.
- Remove the catalog reference that no longer authenticates modified display files.
- Permit replacement of same-version display files when needed.
- Include the bundled PhysX runtime for the new desktop PCI IDs without relying on the older feature whitelist.
- Rebuild the nested Control Panel package with the topology and Customize changes already applied.
- Reuse the original XP-compatible SFX launcher rather than assume a modern SFX stub still runs on XP.

The recipe updates PE section/image sizes, characteristics, pointers and checksums, preserving relocation entries where required. These structural edits are necessary parts of the patch set.

Modified-file signatures are invalidated; firmware authentication remains a separate, active mechanism.

## 11. Apply the custom release number without breaking private interfaces

The requested public release label is 382.69. The final display file version is **6.14.13.8269**; the INF uses **10.18.13.8269**, following the original package's distinction between XP binary and INF version formats.

Public resources and installer metadata use 382.69. Private compatibility constants and the original `r367_00` branch identity remain.

Two NVAPI reporting paths were handled:

- `SYS_GetDriverAndBranchVersion`: update the identified public output constant at file offset `0x183FDE`.
- `GetDisplayDriverVersion`: redirect the validated epilogue at file offset `0x870B9` through a small stub at `0x294E40`. Relabel only a successful result whose returned version is exactly 36881; preserve errors, flags, other versions and other output fields.

Source: [version-api.py](sources/version-api.py). Native controls and an XP invalid-version test verified preserved error behavior.

HD Audio **1.3.34.15**, PhysX **9.16.0318** and nView **141.36** retain their bundled versions. The Control Panel application's own version remains distinct from the display-driver release.

## 12. Validation: what passed and what remains unproven

| Area | Evidence | Boundary |
|---|---|---|
| Normal installation | Earlier full setup/reboot succeeded; the current increment retains the installer flow. Runtime files were boot-tested and the rebuilt package verified by extraction. | Complete setup UI was not rerun for this update; not every INF-listed board was tested. |
| Hardware D3D9 | HAL device with hardware vertex processing, explicit VS3/PS3 programs, 64 draws and complete small-render-target readbacks. | Not a benchmark, exhaustive shader test or full-VRAM test. |
| Native use | P4000 native XP acceleration and games were user-reported working; final package installation was also user-tested. | Keep user reports distinct from instrumented clone results. |
| DisplayPort | P4000 and GTX 1080 Ti: HBR3 ×4; 144-Hz RGB10 and 175-Hz RGB8 state/receiver checks; automatic return to RGB10. | Separate physical 175-Hz picture confirmation remained unavailable in the recorded trial. |
| HDMI | Final-build normal picture at 3440×1440/~100 Hz, 543.5 MHz; expected SCDC configuration observed. | 594-MHz custom timing produced no visible picture; high-rate error-counter interpretation remained unresolved. |
| Control Panel | Corrected DisplayPort classification, custom-mode workflow and persistent scaling selections were checked against 355.98. | Targeted conversions; not every output path or differing-aspect geometry. |
| DP update | GTX 980 Ti: normal 3440x1440/100 HBR2 x4 RGB10, native 60 Hz HBR x4 RGB8 fallback, and 1080p RBR x4 RGB10; accelerated checks pass. | Lower-rate tests use this GPU, not a separate DP1.1 board. |
| HDMI recovery | Three failed setup writes produce 640x480 fallback; two failures then success retain the high mode. Normal 3440x1440/100 at 543.5 MHz and 1080p pass accelerated checks. | Latest recovery changes tested on GTX 980 Ti; no separate Pascal/hotplug/resume regression for this increment. |
| Topology/EDID | Workstation page, Manage EDID and the required API path were exercised. | Not a claim that all workstation-only features are enabled. |
| Rebuild | 582 outer files and 469 CPL members match; 16 source blocks compile to exact bytes. | Archive-level byte identity and fresh hardware execution are separate checks. |

For a new system, verify installed hashes, low-resolution output and hardware D3D9 first. Use bounded high-rate trials with a known fallback, check actual link/depth and receiver status, and confirm the physical picture. Then test intended games, audio, hotplug and longer sessions.

Unvalidated areas include full DP 1.4 DSC/HDR/MST functionality, arbitrary depths above 10 bpc, HDMI deep-color/YCbCr, physical DVI regression, full 8/11-GB VRAM access and suspend/resume. INF inclusion alone does not establish board compatibility.

## 13. Nouveau and Mesa findings used to guide the work

The hardware references were explicitly inspected at fixed revisions:

- **Linux/Nouveau:** v6.12, commit `adc218676eef25575469234709c2d87185ca223a`.
- **Mesa:** mesa-24.3.0, commit `f1f246cfda65eff82fba3be1caf2d23bdeda60cc`.

These references identified hardware operations to locate in the Windows binaries. Windows structures, offsets and calling conventions were established independently; Linux code was not copied into XP.

### Graphics initialization and contexts

Under `drivers/gpu/drm/nouveau/nvkm/engine/gr/`, the explicitly compared files were `gm200.c`, `gp104.c`, `gp102.c`, `ctxgm200.c`, `ctxgp104.c`, `ctxgp102.c` and shared `ctxgp100.c`.

| Area | Maxwell code retained by GP104/GP102 | Pascal-specific selections/differences |
|---|---|---|
| GR initialization | `gm200_gr_oneinit_tiles`, `gm200_gr_oneinit_sm_id`, `gm200_gr_init_gpc_mmu`, active-LTC setup, common exception scaffolding and `gm200_gr_rops`. | GP100 ROP/FECS/shader exception setup, `gp102_gr_init_swdx_pes_mask`, Pascal ZBC/classes and different table capacities. |
| Context generation | Common main/bundle generators, GM107 SM IDs, GM200 distribution-skip/TPC-mask and related helpers. | Pascal page-pool, attribute-buffer and SMID setup; GP102 additionally installs `gp102_grctx_generate_r408840`. |
| Context accounting | Some bundle/page-pool dimensions remain shared. | Different token/attribute/alpha counts and graphics-preemption allocation parameters. |

These details guided searches for distinctive register sequences in the Windows binaries and supported choosing 368.81. They did not justify treating a GP102 context as an unchanged GM200 context. [GM200 source](https://github.com/torvalds/linux/blob/adc218676eef25575469234709c2d87185ca223a/drivers/gpu/drm/nouveau/nvkm/engine/gr/gm200.c), [GP104 source](https://github.com/torvalds/linux/blob/adc218676eef25575469234709c2d87185ca223a/drivers/gpu/drm/nouveau/nvkm/engine/gr/gp104.c), [GP102 source](https://github.com/torvalds/linux/blob/adc218676eef25575469234709c2d87185ca223a/drivers/gpu/drm/nouveau/nvkm/engine/gr/gp102.c).

### Firmware, command submission and memory management

Both Pascal GR implementations reuse `gm200_gr_load`, `gm200_gr_fecs_acr` and `gm200_gr_gpccs_acr`, but the device tables select Pascal ACR/SEC2 implementations. That combination explains why a shared graphics loader does not imply a compatible complete secure-boot chain. Relevant paths are `subdev/acr/gp102.c`, `engine/sec2/gp102.c` and `engine/device/base.c`. The distinction between host descriptors and intact signed payloads was directly useful to the Windows investigation. [Pascal ACR](https://github.com/torvalds/linux/blob/adc218676eef25575469234709c2d87185ca223a/drivers/gpu/drm/nouveau/nvkm/subdev/acr/gp102.c), [Pascal SEC2](https://github.com/torvalds/linux/blob/adc218676eef25575469234709c2d87185ca223a/drivers/gpu/drm/nouveau/nvkm/engine/sec2/gp102.c).

`engine/fifo/gp100.c` retains substantial GM200/GM107 channel machinery while changing Pascal runlist insertion, fault interpretation and channel classes. The Windows result reuses its existing command-submission path; it is not a port of Nouveau's scheduler. [Pascal FIFO](https://github.com/torvalds/linux/blob/adc218676eef25575469234709c2d87185ca223a/drivers/gpu/drm/nouveau/nvkm/engine/fifo/gp100.c).

`subdev/mmu/gp100.c` retains common memory helpers but selects Pascal VMM behavior in `vmmgp100.c`; it also has an explicit `GP100MmuLayout`-dependent fallback to GM200. `subdev/fb/gp102.c` reuses GM200 framebuffer setup while adding Pascal memory-size/remap/VPR work; `ramgp102.c` uses GP100 RAM initialization. These are useful implementation boundaries, not proof that XP selects the same MMU layout or exposes all physical VRAM. [Pascal MMU](https://github.com/torvalds/linux/blob/adc218676eef25575469234709c2d87185ca223a/drivers/gpu/drm/nouveau/nvkm/subdev/mmu/gp100.c), [Pascal framebuffer](https://github.com/torvalds/linux/blob/adc218676eef25575469234709c2d87185ca223a/drivers/gpu/drm/nouveau/nvkm/subdev/fb/gp102.c).

### DisplayPort and HDMI

The inspected display sources included `nvkm/engine/disp/gm200.c`, `gp100.c`, `gp102.c`, `gf119.c`, `gk104.c` and `dp.c`. Pascal reuses important GM200 SOR/HDMI/SCDC functionality and GF119 display operations. These references helped distinguish rate programming, full training, stream depth, HDMI enable and scrambling state.

`drivers/gpu/drm/display/drm_dp_helper.c` provided the extended-DPCD capability model. `drivers/gpu/drm/nouveau/dispnv50/disp.c` provided examples of link-bandwidth/depth selection and HDMI-versus-dual-link-DVI handling; `dispnv50/head.c` distinguished framebuffer precision from link output depth. The Windows patches independently implement the relevant limited behavior through the existing XP interfaces. [DP helper](https://github.com/torvalds/linux/blob/adc218676eef25575469234709c2d87185ca223a/drivers/gpu/drm/display/drm_dp_helper.c), [Nouveau display policy](https://github.com/torvalds/linux/blob/adc218676eef25575469234709c2d87185ca223a/drivers/gpu/drm/nouveau/dispnv50/disp.c).

### Shader/compiler compatibility

At the pinned Mesa revision, `src/nouveau/codegen/nv50_ir_target.cpp` selects `getTargetGM107` for chipset families `0x110`, `0x120` and `0x130`. Related files `nv50_ir_target_gm107.cpp`, `nv50_ir_emit_gm107.cpp`, and Gallium's `nvc0_program.c`/`nvc0_screen.c` show shared compiler machinery alongside chipset-aware class/state handling.

This supported investigating compiler reuse; actual NVIDIA VS3/PS3 execution supplied the runtime evidence. The XP driver retains NVIDIA's compiler. [Mesa target selection](https://gitlab.freedesktop.org/mesa/mesa/-/blob/f1f246cfda65eff82fba3be1caf2d23bdeda60cc/src/nouveau/codegen/nv50_ir_target.cpp).

## 14. Address and hash reference for reviewers

Addresses described as **VA** are preferred-image addresses, not live load addresses. The core XP modules use preferred image base `0x10000`; the Control Panel modules discussed here use `0x10000000`. Use the PE section table to convert VA/RVA to file offset. Do not assume `file_offset = VA - image_base` for every file; the Control Panel and NVAPI layouts differ.

| Module | Key location | Final purpose |
|---|---|---|
| `nv4_disp.dll` | VA `0xB4E1E`, `0xB6FBF` | Pascal root/base display-object admission. |
| `nv4_mini.sys` | Resource VAs `0xC33F90`…`0xC34008`, `0xC35118/30/54` | Selected ACR and SEC2 resource descriptors. |
| `nv4_mini.sys` | VA `0x7271E3` → `0xD06920` | Guarded SEC2 boot-data adapter. |
| `nv4_disp.dll` | File `0x19947` | GeForce SetEDID admission branch. |
| `nvWsS.dll` | VA `0x1011658B` → `0x10257FE7` | Workstation/topology predicate. |
| `nv4_disp.dll` | VA `0x48280` | DP rate acceptance. |
| `nv4_mini.sys` | VA `0x44DFF4`, `0x443704` | Full training and extended DPCD capability discovery. |
| `nv4_disp.dll` | VA `0x47E50`, `0x492A9`, `0x492E5`, `0x4A0E8` | Matched trained-link selection, depth fallback and insufficient-capacity rejection. |
| `nv4_mini.sys` | VA `0x44C737` | Return one successfully trained rate/lane pair. |
| `nv4_mini.sys` | VA `0x443D49`, `0x457EEE` | Candidate-mode bandwidth ceiling. |
| `nvcpl.dll` | Central mask/type conversions; VA `0x10119EA7` | Digital-output classification and scaling-cache refresh; original Customize gate restored. |
| `nv4_mini.sys` | VA `0x8742B0` | Preserve legacy HDMI summary identity. |
| `nv4_disp.dll` | VA `0x4111F` | HDMI-aware preservation of the stock DVI rule. |
| `nv4_mini.sys` | VA `0x4567A6`, `0x45889E`, `0x79C57A` | Early/late HDMI policy and resolved-connector handling. |
| `nv4_mini.sys` | VA `0x79C502`, `0x6E3171` | HDMI setup transaction and bounded native-write retries. |
| `nv4_disp.dll` | VA `0x49681`, `0x4988D/92`, `0x49C35` | Arm, consume and propagate HDMI mode failure. |
| `nvapi.dll` | File `0x183FDE`, `0x870B9`, `0x294E40` | Public version reporting. |

Key final SHA-256 values:

```text
nv4_mini.sys
1399a96e80d03ae0ce53bf13dafbaf752df4569b5e4271e24966c5e47b524ef6

nv4_disp.dll
28544e763088d1c3fc56a72770e14cd1318274b47f8c65c409eb288eda067297

nvapi.dll
d0af05448a70b7cc3302cb496b92f0225ccf1c0b56870ce0abcc6913f067c2a0

nvcpl.dll (inside Control Panel)
ea3fdd329d2273ccd81343af9dc1036835683941e4bf2429544256d7413fb787

nvDispS.dll (inside Control Panel)
246fed8b2c0247f5b1e177b6cac1f16bda9574b1d8dceed69ca36ab78fd6f936

nvWsS.dll (inside Control Panel)
f08267e58a8c50bda39d3b47396224e85c3426a88b3a8b500fb028a09b690b2b
```

The matching release is **Forceware 382.69 (10-3-26)**. Repacked archives need not match the release EXE hash; the exact component hashes and verified member inventories are the reproduction checks.
