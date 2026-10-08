<a id="how-forceware-38269-was-built-from-nvidia-36881-for-windows-xp"></a>

# Rebuilding Forceware 382.69

This guide documents the **10-8-2026 build** of the custom NVIDIA 368.81-based Windows XP 32-bit driver. **382.69 is the project's release number.** The source provided here is the patcher and added C/assembly routines; NVIDIA's proprietary driver source is not included.

Start with the reconstruction commands, then use the implementation sections to review the changes by subsystem.

1. [Rebuild the package](#1-rebuild-the-package)
2. [Pascal initialization and rendering](#2-pascal-initialization-and-rendering)
3. [DisplayPort](#3-displayport)
4. [HDMI](#4-hdmi)
5. [Control Panel, scaling and EDID](#5-control-panel-scaling-and-edid)
6. [Installer, GPU list and build identification](#6-installer-gpu-list-and-build-identification)
7. [Validation and limits](#7-validation-and-limits)
8. [Nouveau and Mesa findings](#8-nouveau-and-mesa-findings)
9. [Address and hash reference](#9-address-and-hash-reference)

<a id="2-rebuild-instructions"></a>

## 1. Rebuild the package

<a id="1-what-can-be-reproduced-with-this-directory"></a>

### Package contents

| File | Purpose |
|---|---|
| [rebuild.py](rebuild.py) | Reconstructs the package from the exact stock installer and two supplied firmware-donor modules. |
| [patches.json](patches.json) | Input hashes, output hashes, byte guards, edits, firmware extraction instructions and the complete package/CPL file inventory. |
| [sources/](sources/) | Readable C/assembly for the added routines, link scripts and the NVAPI version-reporting patch generator. |
| [verify_sources.py](verify_sources.py) | Compiles the retained patch blocks and HDMI/DisplayPort scaling and Control Panel routines, then independently verifies the OpenGL display-class patch. |
| [sources/opengl-display-class.py](sources/opengl-display-class.py) | Guarded recipe for adding the missing OpenGL display class to the preceding Forceware ICD. |
| [templates/](templates/) | Final INF, installer configuration and text files used during reconstruction. |
| [desktop-gpus.json](desktop-gpus.json) | All 50 Maxwell/Pascal desktop INF records, including subsystem-qualified OEM entries. |

The manifest applies the final changes directly to the exact vendor inputs.

A verified rebuild matched **585 outer-package files and all 469 Control Panel files byte-for-byte**. The remaining two outer files are the regenerated Control Panel archive and `SHA256SUMS.txt`. Both archives passed extraction checks; the retained and newly added compiled source blocks matched the driver instructions. The OpenGL table patch is independently regenerated and compared by its source recipe.

Compression, timestamps and tool versions can change archive hashes while preserving identical driver files. The reproduction check is the exact extracted payload.

<a id="21-obtain-the-exact-original-inputs"></a>

### 1.1 Obtain the exact inputs

Use the **32-bit international** packages. An x64 module or a different release is not an interchangeable donor.

1. [NVIDIA 368.81 Windows XP 32-bit international](https://us.download.nvidia.com/Windows/368.81/368.81-desktop-winxp-32bit-international.exe): the full base installer.
2. [Quadro 376.84 Windows 7/8 x86 international](https://us.download.nvidia.com/Windows/Quadro_Certified/376.84/376.84-quadro-grid-desktop-notebook-win8-win7-32bit-international-whql.exe): supplies the ACR, SEC2 and GP107 graphics resources. NVIDIA lists the P4000 among this release's supported additions. [Official release information](https://www.nvidia.com/download/driverresults.aspx/115308/en-us/).
3. [GeForce 378.78 Windows 7/8 x86 international](https://us.download.nvidia.com/Windows/378.78/378.78-desktop-win8-win7-32bit-international-whql.exe): supplies the VPR resources.

The firmware donors are their **expanded `Display.Driver/nvlddmkm.sys` files**, not the entire Windows 7 driver stacks. Extract their installers with 7-Zip. If the driver is stored as `nvlddmkm.sy_`, extract that CAB member again to obtain `nvlddmkm.sys`. Keep the two identically named donor modules in separate directories. No donor installation or execution is necessary.

Required SHA-256 values:

| Input | SHA-256 |
|---|---|
| Full stock XP 368.81 EXE | `eaaef0650b6c6a99a2ed70d5e15aaf5221570ae596ca51784ff5e6fc7e5482f1` |
| Expanded Quadro 376.84 `nvlddmkm.sys` | `84fcd8f31466956f40f1aebc833ef4b23c30b0077e61a842257b4076e4482633` |
| Expanded GeForce 378.78 `nvlddmkm.sys` | `467bdc2e47f4f36330ed011520b9ac79e3051c20728a60e5a2ecebda0228152f` |

The builder rejects incorrect input hashes. NVIDIA components retain their applicable licenses.

<a id="22-run-the-builder"></a>

### 1.2 Run the builder

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
3. Extracts 18 precisely identified firmware/resource records from the supplied donors and validates every decoded payload hash.
4. Applies the final byte edits, checking original bytes and expected output hashes.
5. Writes the final INF/configuration files and preserves the selected original components.
6. Rebuilds the nested Control Panel SFX with the original XP-compatible launcher.
7. Generates package checksums and builds the full outer SFX.
8. Extracts both rebuilt archives again and verifies their contents.

Outputs include:

```text
build-38269/
  Forceware 382.69 (10-8-2026).exe
  Forceware 382.69/
  rebuild-result.json
  work/
```

`rebuild-result.json` should report 587 package files, 585 exact release-file matches, 469 exact Control Panel member matches, and successful extraction checks. Scratch files and compiler outputs belong under the build directory; they are not installed by the driver.

<a id="23-optionally-rebuild-the-added-machine-code-from-source"></a>

### 1.3 Verify the added machine code

The byte-replay builder does not compile C. For an independent check of the readable source, install/use GNU `as`, `ld`, `objcopy`, and GCC with freestanding `-m32` compilation support. The successful comparison used GCC 13.3.0 and GNU Binutils 2.42.

```bash
python3 verify_sources.py \
  --package "build-38269/Forceware 382.69" \
  --cpl build-38269/work/cpl \
  --out source-check
```

This checks the compiled patch blocks at their locations in the rebuilt PE files, including the HDMI/DisplayPort scaling wrappers and separate Control Panel pages.

Other compiler versions may emit different instructions; investigate mismatches before substituting them. The manifest defines the tested binary result.

<a id="24-install-and-validate-separately"></a>

### 1.4 Install and validate

Run the outer EXE or `setup.exe` from the extracted folder. When upgrading, select **Custom (Advanced) → Perform a clean installation**, then restart. These are modified display files; original NVIDIA catalog signatures no longer authenticate the modified payload.

For QEMU testing, make the passed-through GPU the guest's primary VGA device. The tested configuration used `x-vga=on` with no emulated VGA.

Validate installation and rendering before high-bandwidth modes, following [section 7](#7-validation-and-limits).

<a id="3-existing-pascal-support-in-36881"></a>

## 2. Pascal initialization and rendering

XP 368.81 already contains substantial Pascal hardware and graphics-class support. Miniport routines at preferred VAs `0x6010F0`, `0x6F8A60` and `0x600EC0` correspond to Pascal page-pool, GPC/PES-mask and attribute-buffer operations. The display DLL recognizes graphics class `0xC197` and a Pascal channel-class path.

The patches connect and correct this implementation. Windows 7 binaries supply selected firmware resources; XP retains its own operating-system interfaces and rendering/compiler machinery. Descriptive internal names here are inferred from disassembly and behavior, rather than NVIDIA source symbols.

<a id="4-expose-the-existing-pascal-display-paths"></a>

### 2.1 Display-object selection

In `nv4_disp.dll`, the class-selection logic failed to handle Pascal capability bit `0x80000`, preventing the required display objects from being allocated.

Two changes repaired this:

1. At preferred VA `0xB4E1E`, branch to a 51-byte stub at `0x29FDC5`. When bit `0x80000` is present, prepare the existing root-allocation arguments and select class `0x9870`, continuing through the original allocation path. For other GPUs, replay the displaced instructions and return to the stock selection chain.
2. At `0xB6FBF`, expand an existing base-channel selection mask from `0x600000` to `0x680000`. This adds the same Pascal display bit to the existing `0x927C` path. The original allocation and error handling remain in use.

The allocated objects use the existing XP acceleration path. Source: [display-root.s](sources/display-root.s); the manifest contains the mask and PE edits.

The GP100 bit was not added. GP100 and GP108 are excluded from the current INF.

<a id="5-gp102-required-a-coherent-firmwarehost-interface-repair"></a>

### 2.2 GP102 firmware and host interface

GP102 additionally requires compatible ACR, VPR and SEC2 resources and a host-side boot-descriptor adapter.

<a id="51-replace-the-selected-acr-resource-set"></a>

#### Replace the selected ACR resource set

The failing path reached the selected authenticated-loader firmware and returned raw status `0x23`. Disassembly of that selected firmware identified a version comparison: the target GP102 required version 3, while the XP-selected firmware classified it as version 2.

Six complete ACR resources were taken from the exact Quadro 376.84 x86 miniport. These include the payload and its associated header/signature metadata. Compressed donor records were decoded, checked, appended to the XP image and referenced through the existing XP resource descriptors. Resource IDs were `0x1AC`, `0x1AE`, `0x1B0`, `0x1B2`, `0x1B4` and `0x1B6`.

The 16,384-byte ACR payload has SHA-256:

```text
cd7af91422cccf09eff250040e70d3f48430cfe7c07d7130efd82ee88c085b3c
```

This removed the observed version failure without patching the firmware's validation result or altering its signed instructions.

<a id="52-replace-the-matched-vpr-resources"></a>

#### Replace the matched VPR resources

The matched VPR resources establish the protected-memory-region state expected by the XP verifier.

The working approach copied the complete matched VPR set from GeForce 378.78 x86: a 3,328-byte image, 40-byte header, production and debug signature records, signature location and signature index. Six existing resource-address operands at `0x6DE9B1` through `0x6DE9D3` were redirected. Their existing relocation entries were preserved.

The VPR image hash is:

```text
6b977b60ebfe5023b6f29a90f6faf28b69f69f15e76fae3bc4d2f061cb59520a
```

The existing verifier and permission checks remain active.

<a id="53-use-a-matched-sec2-tuple"></a>

#### Use a matched SEC2 tuple

Use this matched Quadro 376.84 SEC2 tuple:

| Resource | Decoded length | Donor descriptor VA |
|---|---:|---:|
| SEC2 image | 203,776 bytes | `0x698624` |
| SEC2 descriptor | 656 bytes | `0x69863C` |
| SEC2 signature | 192 bytes | `0x698660` |

The image hash is `24fc5122aaf36722987ffc74b04d55ba476e62a72565c654d87406ed36148625`. Associated descriptor and signature hashes are recorded in `patches.json`.

The final firmware combination is **ACR 376.84 + VPR 378.78 + SEC2 376.84**.

<a id="54-adapt-the-sec2-boot-descriptor-at-the-correct-boundary"></a>

#### Adapt the SEC2 boot descriptor at the correct boundary

The host and SEC2 bootloader use different descriptor layouts:

- The XP host constructed a 56-byte `loader_config_v1`-shaped descriptor.
- The selected newer bootloader expected an 84-byte `flcn_bl_dmem_desc_v2`-shaped descriptor.
- The original embedded host buffer was only 76 bytes. Enlarging it in place would overwrite neighboring state.
- The final WPR destination already reserved 256 bytes, sufficient for the new descriptor.

The solution was a **198-byte host-side adapter** at preferred VA `0xD06920`, called instead of the existing final-copy call at `0x7271E3`. It builds an 84-byte temporary stack descriptor, maps the DMA/code/data/entry/argument fields to the expected positions, and invokes the existing copy function `0x470D10`.

The adapter only activates when all observed compatibility guards match: Falcon ID 7, old copy length `0x38`, destination reservation `0x100`, firmware build `0x014A7C8C` and boot entry `0xFD00`. Otherwise it follows the original copy path. The signed firmware and original embedded host structure remain intact.

Source: [sec2-bootdesc.S](sources/sec2-bootdesc.S). Tests verified field placement, boundary protection, register/stack preservation, guard fallbacks and all 84 uploaded bytes. SEC2 queues and adapter initialization completed, allowing hardware D3D9/Shader Model 3 testing.

<a id="opengl-display-parent-recognition"></a>

### 2.3 OpenGL display-parent recognition

The OpenGL ICD requires a separate display-class list from the display DLL. `nvoglnt.dll` originally listed eleven classes, headed by its highest-priority entry `0x9770`, but omitted `0x9870`. On GTX 1080 Ti the resource manager advertises `0x9870`; the old selector finds no matching display class and skips the required parent object. A later child allocation fails, preventing graphics-context initialization and eventually causing an application exception.

The 378.78 x86 OpenGL driver uses the same old entries with `0x9870` prepended. The XP patch adds that twelve-entry list at preferred VA `0x6A45F7A0`, changes creation and teardown lookups at `0x69E96249`/`0x69E963CB` to the new pointer/count, and updates `.rdata` virtual size and the PE checksum. Existing relocation records remain valid. The original eleven entries and selector are preserved; no newer context offsets or shader code are copied.

Use [verify_sources.py](verify_sources.py) to independently check the final dated ICD; it normalizes the verified build metadata before invoking [opengl-display-class.py](sources/opengl-display-class.py). The latter can also apply the OpenGL increment to its exact preceding Forceware ICD. `rebuild.py` already includes the complete stock-to-final patch through `patches.json`.

GTX 1080 Ti tests passed glxgears and GPU Caps Viewer 1.37 Simple Mesh, Furry Cube, Illuminated Torus and Tessellation, with clean exits and preserved hardware D3D9 rendering. See [OpenGL implementation](templates/package/Documentation/OpenGL-update.md) and the [current validation table](#7-validation-and-limits).

<a id="9a-correct-cuda-opencl-and-gpu-physx-gpu-name-lookup"></a>

### 2.4 CUDA, OpenCL and GPU PhysX

The reproduced GTX 1080 Ti failure was a missing internal GPU name, not a missing CUDA compiler or PhysX implementation. RM command `0x20800111` reached short-name lookup `0x557A80`; PCI ID `1B06` was absent from the 640-record table, so lookup returned `0x56`. CUDA initialization returned 100, OpenCL found no platform, and FluidMark used CPU PhysX.

The final table retains all 640 original records and appends accurate names for ten IDs: `1B02`, `1B06`, `1B83`, `1C04`, `1C06`, `1C31`, `1C83`, `1CB1`, `1CB2`, `1CB3`. Seven table references and three loop bounds are changed, with 1,300 additional HIGHLOW relocation entries for the copied pointers. Unknown devices remain rejected; existing successful lookups are unchanged.

[sources/gpu-names.py](sources/gpu-names.py) independently reconstructs the name-only correction from the exact 10-4 miniport. Its separate [internal GPU list](sources/compute-gpus.json) retains GP107 while [desktop-gpus.json](desktop-gpus.json) describes current INF eligibility. `patches.json` contains the complete stock-to-final edits, including subsequent build metadata. The GP107 code/resources and PhysX installer IDs remain intact, but the main display INF excludes GP107 following reported Code 10 failures.

On GTX 1080 Ti the name-only correction passed CUDA context create/synchronize/destroy, OpenCL kernel compilation/execution with 8,192 checked GPU results, GPU PhysX FluidMark rendering, and 64 hardware D3D9 draw/readbacks. The isolated native lookup harness passed 4,872 calls including original records and preferred/relocated images. Other listed GPUs were checked statically, not individually hardware-tested. See [compute update](templates/package/Documentation/Compute-update.md).

<a id="gp107-registration-and-graphics-contexts"></a>

### 2.5 GP107 experiment and exclusion

The GP107 addition retains the existing GP106 registration at `0x46F7AA`, then registers GP107 index `0x3B` with its own 82-pointer table. Matched XP callbacks, GP107 context constants and intact 376.84 graphics resources are installed through the added block at `0xD07C40`. Existing firmware/secure initialization and other GPU family tables are preserved. Newer-driver private offsets are not reused.

See [GP107 implementation and limitations](templates/package/Documentation/GP107-experimental.md) and [assembly source](sources/gp107/gp107.s). The experimental block passed offline execution checks; testers subsequently reported GP107 Code 10, so its display INF entries are withheld.

<a id="7-displayport-negotiate-the-link-then-choose-a-compatible-output-depth"></a>

## 3. DisplayPort

<a id="71-accept-the-higher-rate-codes"></a>

### 3.1 Accept the higher rate codes

At display DLL VA `0x48280`, XP's wrapper accepted rate codes 6 and 10, corresponding to RBR/HBR, but substituted the current value for codes 20/30. Consequently an API request could return success without actually changing the link rate.

The new 24-byte stub at `0x356600` admits codes 20 and 30 while preserving the existing behavior for other values. The source is [dp-api-rate.s](sources/dp-api-rate.s).

<a id="72-select-full-link-training"></a>

### 3.2 Select full link training

The miniport must also select full training for HBR2/HBR3.

The patch at miniport VA `0x44DFF4` routes HBR2/HBR3 through the existing full-training implementation. Its 20-byte stub is at `0x89B86A`; see [dp-full-training.s](sources/dp-full-training.s). The existing Pascal rate setter already understood these rates.

<a id="73-read-extended-receiver-capabilities"></a>

### 3.3 Read extended receiver capabilities

The XP code originally read 12 bytes of base DPCD data. It therefore missed the extended-capability flag at `0x0E`. The tested receiver advertised HBR2 in its base block, but HBR3 in its extended block at `0x2200`.

The updated path reads 15 bytes, checks the flag, and conditionally reads and validates the extended block before calling the original parser. Failed or invalid extended reads retain the base capabilities. The 126-byte stub is at `0xD06A00`; see [dp-extended-caps.s](sources/dp-extended-caps.s).

<a id="74-extend-automatic-training-choices"></a>

### 3.4 Extend automatic training choices

The automatic configuration table contained six RBR/HBR lane/rate combinations. The final table preserves those six entries and adds **HBR2 ×4 and HBR3 ×4**. Six existing relocated table pointers are updated, the scan length changes from 72 to 96 bytes, and the default preference value changes from `0x654321` to `0x65432178`.

Capacity follows successful training. Higher-rate one- and two-lane automatic entries were not added; the unsafe guessed-link fallbacks are removed as described below.

<a id="75-select-a-matched-trained-link-and-validate-depth"></a>

### 3.5 Select a matched trained link and validate depth

Miniport hook `0x44C737` reads the successful-training bitmap at output+`0x2D00`, bounds it by receiver limits, and returns the highest-capacity **matched rate/lane pair**. Passive discovery with no history returns validated receiver ceilings. Active mode preparation requests native probing if history is empty and returns 0/0 if no pair succeeds. The display selector at `0x47E50` validates the prepared pair instead of guessing another configuration.

Miniport candidate-mode calculations at `0x443D49` and `0x457EEE` use at most 8 bits per color for admission. Actual mode selection at display VA `0x492A9` retains the requested depth when it fits; higher depths fall back to 8 bits when that fits, otherwise the mode fails. The calculation retains 8b/10b coding and the existing 0.5% clock margin. Unknown depth codes and arithmetic overflow fail closed.

Hooks at `0x492E5` and `0x4A0E8` remove the old guessed-link fallbacks. The existing hardware training/error paths remain in use. A previously successful probe cannot guarantee a changed cable or receiver will retrain.

Source: [dp-policy.c](sources/dp-trained/dp-policy.c), [miniport adapter](sources/dp-trained/mini-hooks.s), [display adapters](sources/dp-trained/disp-hooks.s). Detailed policy: [DisplayPort update](templates/package/Documentation/DisplayPort-update.md).

GTX 980 Ti tests confirmed normal native 3440x1440/100 on HBR2 x4 with RGB10, native 60 Hz on restricted HBR x4 with automatic RGB8 fallback, and 1080p on restricted RBR x4 with RGB10. Over-budget timings were rejected. These tests exercise real lower link rates, not a separate older DP1.1 GPU.

<a id="displayport-startup-preparation"></a>

### 3.6 Startup preparation

Passive capability discovery and active mode preparation have different requirements. When the native training bitmap is empty, passive queries return validated receiver ceilings. These describe capabilities; they do not certify training. Active mode preparation requests the native GPU-eligible probe and accepts only a matched pair recorded as successfully trained. A failed active preparation supplies 0/0 so existing mode selection rejects insufficient capacity.

- Query initialization at `0x44C6CD` preserves an exact private preparation marker across the native buffer clear.
- Query hook `0x44C737` invokes the adapter at `0xD68F00`. Only marked active preparation with an empty low-byte training bitmap invokes native probe `0x443BF0`.
- Display call sites `0x49272` and `0x4A05D` use the preparation helper at `0x356B00`; ordinary `0x47DD0` capability queries remain passive.
- If an already-owned active output prevents probing and the query returns an empty pair, the display helper invokes existing `0x481A0` configuration once with default settings and matching-settings early return disabled. It then repeats the marked query. Only actual native training successes satisfy mode selection; a configuration error is never itself converted into a successful pair.
- The native probe retains source eligibility, receiver bounds and normal output serialization. The preparation marker is consumed before exporting native flags, including the non-DP return hook at `0x44C992`.
- No persistent state is placed in an existing object field. The miniport executable section grows by 512 bytes; the display helper uses its extended executable section. Existing HDMI transaction storage and GP107 tables are separate.
- Nonempty training history and its existing hot-plug invalidation lifecycle remain in use. Mode selection still uses a matched rate/lane pair, validates payload, falls back to RGB8 when necessary, and rejects insufficient capacity.

The policy test covers all 256 bitmap values against RBR/HBR/HBR2/HBR3 and one/two/four lanes for active and passive queries, invalid receiver values, failed preparation and depth fallback. Primary GTX 1080 Ti startup, HBR3 x4 at 3440x1440/100 and rendering tests passed. This does not identify the cause of every remote monitor report or establish all-monitor compatibility.

<a id="displayport-receiver-reset-wake-correction"></a>

### 3.7 Display sleep/wake recovery

At display DLL preferred VA `0x19E23`, replace `0F B6 4C 24 17` (`movzx ecx, byte ptr [esp+0x17]`) with `B9 FF FF FF FF` (`mov ecx,-1`), then recalculate the PE checksum. Source: `sources/dp-wake-lane-restore.s`. The manifest guards exact input bytes and final file hashes.

The link-status retraining caller reads DPCD `0x101`, the receiver's current lane count. During a traced ten-minute display sleep, that register reset to one lane while the native `0x782E` query still reported the saved HBR3 x4 configuration. Passing the receiver's value explicitly overrode the correct saved count. The existing default sentinel instead lets `0x481A0` use the configured lane count and rate. Native `0x7829` configuration and `0x731343` training still perform and validate the operation; failure reporting is preserved.

Only this link-status retraining caller changes. It does not force four lanes or HBR3, alter manual mode selection, or rewrite HDMI handling. A repeated ten-minute test on GTX 1080 Ti and a direct DisplayPort monitor restored 3440x1440/60 on HBR3 x4 without a recovery modeset; the physical picture was confirmed normal and post-wake Direct3D/OpenGL rendering passed. Other monitor/GPU combinations and whole-system suspend were not validated by that test.

The October 6 clean-install regression repeated the ten-minute display-sleep cycle without a debugger. The receiver again reset to one lane; both source and receiver returned to HBR3 x4 by the 20-second sample and retained all-lane equalization at 60 seconds. No intervening modeset or reboot was used. Post-wake Direct3D, OpenGL, CUDA and OpenCL checks passed. This repeat confirms hardware and rendering state; the earlier traced cycle supplied the physical-picture confirmation.

<a id="automatic-native-displayport-scaling"></a>

### 3.8 Native scaling

Sources: [selector.c](sources/dp-scaling/selector.c) and the reused [trained-link policy](sources/dp-scaling/dp-policy.c). Compile the selector as freestanding x86 with `-Os -fno-pie -fno-stack-protector -fno-jump-tables -fno-tree-switch-conversion -fno-asynchronous-unwind-tables -fno-unwind-tables`. Link its text at `0xD69D40`, with `previous_selector=0xD694C6` and `native_cap=0xD699CE`. The resulting 1,937-byte block contains `dp_output_selector` at `0xD69F33`. `verify_display_updates.py` compiles and compares the complete block and both call targets.

The wrapper calls the existing HDMI/stock policy first; [section 4.5](#45-native-scaling) documents the two shared mode/viewport call sites. It only replaces an eligible derived timing for a single DisplayPort output (native kind 2, protocol 8 or 9). The preferred progressive base DTD must agree with the current native dimensions, complete parsed timing, rounded requested refresh and table type. Some native DP objects retain only the base EDID, so a valid 128-byte base is accepted without inventing extension data.

Admission uses the lower of the native output limit and RGB8 capacity of a genuinely trained rate/lane pair bounded by receiver capability, with the existing 0.5% margin. The mode setter retains its normal depth choice: keep the requested depth when it fits, reduce to 8 bits when required, or reject the mode. No DPCD, EDID, mode-list or forced-refresh override is introduced. Exact custom modes, closest-match requests, unsupported/ambiguous output types and insufficient bandwidth retain the previous result. The existing HDMI policy and its 594 MHz ceiling are unchanged.

On GTX 1080 Ti over direct DisplayPort, ordinary 640×480/60 selected a native 3440×1440/60 signal at 319.75 MHz. Native Control Panel Apply produced the expected viewports: 1920×1440 for fixed aspect ratio, 3440×1440 for full-screen, and 640×480 for no scaling. Fullscreen hardware Direct3D draw/readback and OpenGL checks passed after restart. Real HBR-only training retained the native timing by reducing RGB10 to RGB8; real RBR-only training refused promotion and retained the prior valid lower-clock output. Explicit 3440×1440/175 remained functional at HBR3 ×4 and RGB8.

Automatic promotion requires the matching preferred timing and does not transfer a high desktop refresh into lower-resolution games. This release retains the tested 60 Hz automatic scaling behavior on the tested display. It makes no universal claim for DisplayID-only preferred modes, MST, multi-display or all monitor/cable combinations.

<a id="9-hdmi-identification-scdc-and-clock-policy"></a>

## 4. HDMI

<a id="91-preserve-hdmi-identity"></a>

### 4.1 Preserve HDMI identity

A legacy EDID summary stored successive vendor blocks in one slot. An HDMI Forum block, OUI `0xC45DD8`, could overwrite the legacy HDMI OUI `0x000C03`, causing the driver to report a non-HDMI connection.

The 55-byte hook at miniport VA `0x8742B0` now jumps to a 118-byte priority routine at `0xD69100`. A legacy HDMI vendor block must contain its three-byte OUI and two-byte physical address. The complete 31-byte summary slot is cleared before accepting HDMI, so a shorter HDMI block cannot inherit optional capability bytes from a longer preceding vendor. Payloads crossing the CTA data-block boundary or extension checksum are rejected. Once accepted, HDMI identity and payload cannot be replaced by unrelated vendor blocks. Forum-only and non-HDMI behavior is retained. Raw EDID data and the separate capability parser remain intact. Sources: [hdmi-vendor-summary.s](sources/hdmi-vendor-summary.s), [hdmi-vendor-priority.s](sources/hdmi-vendor-priority.s).

The original CTA parser zeroes its 107-byte output before parsing; the display refresh path also clears that output before calling it. Reusing the HDMI identity therefore cannot carry it into the next monitor. Tests execute the extracted x86 parser: 88 cases cover vendor order, lengths, long-to-short replacement, malformed boundaries and HDMI-to-DVI refresh. All non-vendor summary bytes and native return statuses remain unchanged. In an XP clone, the reported LG EDID returns native HDMI=true and a 594 MHz policy ceiling; a no-HDMI control returns false and 165 MHz. This verifies identification and policy, not physical 4K60 output on that reported monitor.

<a id="92-apply-the-hdmidvi-policy"></a>

### 4.2 Apply the HDMI/DVI policy

In the display DLL, the patch at `0x4111F` queries HDMI status. A positive GPU/output-and-sink HDMI result retains single-link TMDS behavior; other connections retain the original 165-MHz DVI comparison.

The miniport extension is limited to GM200/GM204/GM206 and GP102/GP104/GP106/GP107 on the digital TMDS/SOR path. GP107 retains that internal family check but is excluded from the display INF. Its chosen ceiling is **594 MHz for the tested RGB8 path**, bounded by:

- Valid digital EDID, checksum/bounds checks and legacy HDMI identity.
- Sink-advertised TMDS limits and source/board/resource-manager restrictions.
- SCDC and advertised high-rate capability for clocks above 340 MHz.
- A refreshed source query; failed or empty queries clamp conservatively instead of retaining a previous sink's elevated limit.

The shared default at `0x5BD79B` remains **165,000 kHz**, and the scrambling/high-clock-ratio transition remains 340,000 kHz. The project's 594-MHz ceiling is an implementation choice, not HDMI 2.0's universal maximum.

Sources: [hdmi-policy.c](sources/hdmi-policy.c), [hdmi-hooks.s](sources/hdmi-hooks.s), [hdmi-protocol.s](sources/hdmi-protocol.s).

<a id="93-pass-capabilities-and-update-cached-limits"></a>

### 4.3 Pass capabilities and update cached limits

Hooks at `0x4567A6` and `0x45889E` refresh the policy around mode validation and EDID processing. A hook at `0x79C57A` handles the extension after the original handler resolves and class-checks the connector. The display DLL and miniport form a matched pair.

Capabilities pass through control `0x00730293` with marker `0xA0000000`; existing low capability bits retain their meanings and unmarked requests retain stock behavior. A subsequent `0x0073028A` query returns the resolved limit. The Windows cache uses 10-kHz units; the resource-manager limit uses kHz.

The driver uses its existing sink/SCDC and source-programming machinery. A 567-byte inactive capability bridge remains in the image and source verification; the active hooks use the final policy above.

<a id="94-recover-from-failed-high-rate-setup"></a>

### 4.4 Recover from failed high-rate setup

The display hook at `0x49681` arms a GPU/connector-specific transaction before a positively identified HDMI mode above 340 MHz. Private ARM/END commands are intercepted at miniport `0x79C502` before the existing capability setters. State occupies an owned 32-slot table, with generation tracking and a non-blocking atomic lock.

Miniport hook `0x6E3171` retries an armed SCDC setup write at most three times, with native 2 ms delays. A successful acknowledgement is latched. Later SCDC read failures do not invalidate an established link. Outside the transaction, the original single-write behavior remains.

Display cleanup at `0x49892` consumes the mode-local marker and transaction result; `0x4988D` preserves the marker on an existing failure edge. Hook `0x49C35` propagates failure into XP's mode-enable path. In injected-failure tests, XP selected safe 640x480 output before the test helper intervened. This is not restoration of the exact prior mode. NVAPI TryCustomDisplay can still report success when XP substitutes that safe mode; applications must inspect the actual mode.

Source: [recovery policy](sources/hdmi-recovery/scdc-recovery.c), [miniport hooks](sources/hdmi-recovery/scdc-mini.s), [display hooks](sources/hdmi-recovery/scdc-disp.s). The distributed build uses `FAULT=0`. See [HDMI recovery implementation](templates/package/Documentation/HDMI-SCDC-recovery.md).

SCDC availability is not equivalent to EDID readability or input selection. Later reads sometimes failed while the picture remained normal; the cause is unresolved. Hotplug, resume and alternate mode-update paths were not separately validated by these tests.

<a id="automatic-native-hdmi-scaling"></a>

### 4.5 Native scaling

The stock selector at `0x873140` remains in place. Callers `0x45B208` (mode selection) and `0xC748B0` (viewport query, IOCTL `0x232FB4`) both supply the verified `display+0x234` timing table. They now enter the DisplayPort wrapper at `0xD69F33`, which first calls the unchanged HDMI wrapper at `0xD694C6`. This prevents Control Panel Apply from sizing the viewport using a different output timing. Three other callers are unchanged.

Sources: [selector.c](sources/hdmi-scaling/selector.c), [sink.c](sources/hdmi-scaling/sink.c), [native-cap.s](sources/hdmi-scaling/native-cap.s). The verifier extracts the unchanged native selector bytes from the rebuilt miniport for the assembly adapter; no donor OS structure is substituted.

The wrapper runs the stock selector first. Only derived preferred-timing results on a single validated HDMI output are eligible for promotion. It reparses the current complete EDID and applies the lowest of GPU/output, sink and 594 MHz limits. Above 340 MHz, a sufficient HDMI Forum TMDS rate and SCDC declaration are required. It checks the progressive base preferred DTD against native dimensions, clock, totals, porches, sync widths, polarities, current parsed table, type and requested refresh. Candidate computation uses scratch storage; failed checks leave the stock timing, status and flags intact. Exact/custom and closest-match paths stay native. Existing mode validation and paired-driver SCDC setup/recovery remain active.

On a primary GTX 1080 Ti over HDMI, Full-screen, Aspect ratio, No scaling and rejecting changes produced the expected hardware viewports. Overscan cancel/commit/restore passed at 1080p. Automatic scaling from a 1600×900 source into a 3440×1440/100 signal reached 543.5 MHz with successful SCDC setup and a confirmed normal picture. A separate failure-control run rejected the high-clock change after bounded setup retries and returned to the prior low-clock desktop before the test helper's restore. The source size was not sent as a direct unsupported monitor timing.

The executable policy tests cover the 594 MHz ceiling; physical automatic output at that exact clock was not validated. Broader monitor, deep-color, YCbCr, multi-display and connector combinations remain outside this hardware test. Reboot, fullscreen Direct3D and OpenGL regression checks passed with the normal driver and original EDID restored.

## 5. Control Panel, scaling and EDID

<a id="8-correct-control-panel-classification-customize-and-scaling"></a>

### 5.1 Classification and custom resolutions

The older Control Panel treated output bits 8–15 as analog TV. The 368.81 driver placed a digital DisplayPort output in that range, so the UI misclassified a PC display and restricted Customize. The 355.98 comparison used a different bit position for the same connection.

The current `nvcpl.dll` patches central mask/type/index conversions to interpret bits 0–7 as CRT and bits 8–31 as digital outputs. The earlier Customize-only bypass in `nvDispS.dll` is removed; the original eligibility predicate now receives the corrected classification.

A second DFP mask at `nvcpl.dll` VA `0x10119EA7` changes from `FFFF0000` to `FFFFFF00`. This allows the scaling-cache refresh to run for the current output, so fixed-aspect settings persist after Apply, reopening the panel and rebooting. Custom-mode create/test/save/delete and scaling/no-scaling selection were exercised on DisplayPort. The native viewport tests below establish the tested scaling geometry; other monitor combinations remain unverified.

The exact guarded edits are in `patches.json`; this is a targeted repair of the observed conversions, not a global replacement of every similar constant.

<a id="separate-scaling-and-overscan-pages"></a>

### 5.2 Separate Scaling and Overscan pages

`nvcpl.dll` retains native scaling enumeration but removes the later HDTV-format rejection at `0x1012BC63` and the TV exclusion at `0x101390D6`. Native option capabilities and `NoDFPCtrls` remain authoritative; HDMI identity and audio are unchanged.

The Control Panel module `nvDispS.dll` creates an independent instance of the native XP page for **Adjust overscan**, using a cloned vtable at `0x108C3284`. The existing scaling instance stays independent. The wrapper at `0x108C3000` retains native creation, Apply, confirmation and cleanup; its page-info method supplies separate captions with native allocation ownership. All six child-dispatch sites use the instance-aware router. Digital page visibility uses a successful native display-type query; unsupported choices are not fabricated. Thirty new relocations accompany the appended code and cloned vtable, preserving all 98,847 existing relocations.

Source: [sidebar.s](sources/control-panel/sidebar.s). The exact byte manifest includes admission changes, the appended section, native vtable copy, caption/dispatch hooks and relocation directory. `verify_display_updates.py` rebuilds and checks these instructions and required relocated pointers. Overscan resizing is only exposed for timings supported by the native resize implementation; a native ultrawide PC timing may have no resize controls.

<a id="6-topology-and-edid-management-required-two-separate-changes"></a>

### 5.3 Topology and EDID loading

- In `nvWsS.dll`, a guarded replacement for the local workstation-status predicate at preferred VA `0x1011658B` supplies the status expected by that UI path. The stub is at `0x10257FE7`; its source is [topology-predicate.s](sources/topology-predicate.s). This changes the Control Panel's workstation query, not the GPU's actual PCI identity or every product-class restriction in the driver.
- In `nv4_disp.dll`, a branch displacement byte at **file offset** `0x19947` changes from `0x0A` to `0x1B`, allowing the GeForce product-class case through the existing SetEDID path. Other validation remains.

Both changes are installed with the driver. UI visibility and EDID operations were tested separately.

## 6. Installer, GPU list and build identification

<a id="10-build-a-normal-full-installer-and-expand-the-inf"></a>

### 6.1 Full package and desktop INF

The complete stock installer supplies setup, HD Audio, PhysX, nView and the other retained components.

The desktop INF work retained the selected legacy desktop entries and added/retained 50 Maxwell/Pascal records. Subsystem-qualified desktop OEM aliases are kept specific rather than broadly matching device IDs also used by mobile products. Mobile, GP100, GP107 and GP108 GPUs are excluded. Experimental GP107 initialization and its internal names remain in the binary; the normal display INF no longer matches those cards.

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

<a id="server-2003-installer-compatibility"></a>

### 6.2 Server 2003 compatibility

`templates/package/GFExperience/GFExperience.nvi` restricts the XP32 filter to NT 5.1 and silently excludes optional GeForce Experience on NT 5.2 x86. This prevents applying XP's SP3 prerequisite to Server 2003 SP2. Windows XP keeps its SP3 requirement. This installer correction changes no display-platform check or runtime binary. Server 2003 R2 SP2 x86 installation, Control Panel and hardware Direct3D were verified on a primary GTX 1080 Ti. Server 2003 x64 is not covered.

<a id="11-apply-the-custom-release-number-without-breaking-private-interfaces"></a>

### 6.3 Release number and API reporting

The requested public release label is 382.69. The final display file version is **6.14.13.8269**; the INF uses **10.18.13.8269**, following the original package's distinction between XP binary and INF version formats.

Public resources and installer metadata use 382.69. Private compatibility constants and the original `r367_00` branch identity remain.

Two NVAPI reporting paths were handled:

- `SYS_GetDriverAndBranchVersion`: update the identified public output constant at file offset `0x183FDE`.
- `GetDisplayDriverVersion`: redirect the validated epilogue at file offset `0x870B9` through a small stub at `0x294E40`. Relabel only a successful result whose returned version is exactly 36881; preserve errors, flags, other versions and other output fields.

Source: [version-api.py](sources/version-api.py). Native controls and an XP invalid-version test verified preserved error behavior.

HD Audio **1.3.34.15**, PhysX **9.16.0318** and nView **141.36** retain their bundled versions. The Control Panel application's own version remains distinct from the display-driver release.

<a id="build-identification"></a>

### 6.4 Build dates

Each package revision declares `build_date` (MM/DD/YYYY) in `patches.json`. This build uses **10/08/2026**. The display INF, DisplayDriver/Control Panel NVI timestamps, rebuilt display PE headers, embedded July 10 build strings, archive member timestamps and generated SFX headers use the same date. `sources/build-date.py` records reversible metadata edits; the builder rejects mismatched INF/NVI dates and verifies the binary edits. Independent instruction checks normalize only those verified metadata edits.

These dates identify the custom package, not a recompilation of NVIDIA's proprietary code. Historical copyright, firmware and debugger identity are retained. Unchanged audio, PhysX, nView and other vendor components keep their original binary versions and internal dates; the archive dates identify this package. Display version remains 6.14.13.8269. Future builds must refresh all of these display identification fields, and final extracted files must be checked.

<a id="12-validation-what-passed-and-what-remains-unproven"></a>

## 7. Validation and limits

| Area | Evidence | Boundary |
|---|---|---|
| Installation and package | October 8 NVIDIA clean install and restart on GTX 1080 Ti; 13 installed hashes, Code 0, NVAPI version and build date matched. Extraction verifies 587 package files, 469 CPL members and 63 dated metadata records. The retained and added source blocks compile to the inserted instructions. | Other boards were not individually retested. Original partitions are not exercised by clone testing. |
| Direct3D and OpenGL | October 8: fullscreen D3D9 HAL/HWVP, VS3/PS3, 64 draws/readbacks and Present; three OpenGL display-list renders with correct pixels and no GL errors. Earlier builds passed glxgears and GPU Caps Viewer rendering tests. | Functional checks, not conformance, exhaustive shader or full-VRAM testing. |
| CUDA, OpenCL and GPU PhysX | October 6 files after display wake passed CUDA context operations and an OpenCL kernel with 8,192 checked results. October 5 passed a 60-second GPU PhysX benchmark with clean exit. Compute code and the PhysX payload are unchanged. | GPU PhysX was not repeated in the October 6 or October 8 checks; other models were not individually tested. |
| DisplayPort | P4000/GTX 1080 Ti HBR3 ×4; GTX 980 Ti HBR2 ×4 at 3440×1440/100. Real HBR and RBR controls verified depth/capacity fallback. GTX 1080 Ti explicit 3440×1440/175 RGB8 had a confirmed normal picture. October 8 fullscreen 640×480 scaled to 1920×1440 inside native 3440×1440/60. The earlier ten-minute display-sleep test recovered the saved link and passed rendering. | Lower-rate tests used capable GPUs, not a separate DP1.1 board. High-refresh native-mode success does not imply automatic high-refresh scaling or whole-system suspend support. |
| HDMI | October 7 automatic scaling reached 3440×1440/~100 at 543.5 MHz, with successful SCDC setup, correct viewport and a confirmed normal picture. Injected setup failures exercised bounded retries and safe output; later scaling controls restored the prior low-clock desktop. | The 594 MHz boundary passes executable policy tests, but physical automatic output at that exact clock remains unverified. Later sink/cable failures and all connector combinations are not covered. |
| Control Panel and EDID | DisplayPort classification/custom-mode workflow compared with 355.98. October 8 Scaling/Overscan pages loaded; fixed-aspect Apply and native fullscreen viewport passed. Topology, Manage EDID and the required API path were exercised separately. | Overscan resizing is timing-dependent. Physical DVI and every workstation-only feature were not validated. |
| Other GPUs | Earlier P4000 native XP acceleration, games and package installation were user-reported working. GP107 testers still reported Code 10, so its display INF entries remain excluded. | INF inclusion alone is not individual model validation. Experimental GP107 code remains in the binary without a working-support claim. |

For a new system, verify installed hashes, low-resolution output and hardware D3D9 first. Use bounded high-rate trials with a known fallback, check actual link/depth and receiver status, and confirm the physical picture. Then test intended games, audio, hotplug and longer sessions.

Unvalidated areas include full DP 1.4 DSC/HDR/MST functionality, arbitrary depths above 10 bpc, HDMI deep-color/YCbCr, physical DVI regression, full 8/11-GB VRAM access and whole-system suspend/resume. INF inclusion alone does not establish board compatibility.

<a id="13-nouveau-and-mesa-findings-used-to-guide-the-work"></a>

## 8. Nouveau and Mesa findings

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

<a id="14-address-and-hash-reference-for-reviewers"></a>

## 9. Address and hash reference

Addresses described as **VA** are preferred-image addresses, not live load addresses. The core XP modules use preferred image base `0x10000`; the Control Panel modules discussed here use `0x10000000`. The OpenGL ICD uses `0x69500000`. Use the PE section table to convert VA/RVA to file offset. Do not assume `file_offset = VA - image_base` for every file; the Control Panel and NVAPI layouts differ.

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
| `nvoglnt.dll` | VA `0x69E96249`, `0x69E963CB`, table `0x6A45F7A0` | Preserve existing classes and add GP102 display-parent recognition. |
| `nvapi.dll` | File `0x183FDE`, `0x870B9`, `0x294E40` | Public version reporting. |

Key final SHA-256 values:

```text
Display.Driver/nv4_mini.sys
02a4433a11e192bcac7051f8433510fd2ad4a21d0cfa0204520ba0a17d3fb800

Display.Driver/nv4_disp.dll
476cd4001c8a8f5778d984d77aaa124774811754fbc839b5590ed3758241e30a

Display.Driver/nvoglnt.dll
675ba45e88c1762b305054a41c395127033e359eccda49b0eaaca0152a73156d

Display.Driver/nvapi.dll
425f30b4af60d91333ba56475580c93b864e1ff17f8847b03cc4ab1c4431287f

nvcpl.dll
ef7c582626bb18b4ce83723a484fa61dd5f78f1879c66ad70587ac237997af41

nvDispS.dll
8e6092376f755b4e14cdd02ff432f0d52bd723f298c4fd0e3974147074af5341

nvWsS.dll
dd22dce74485a5fde43166e503c670d99b82a25310f3074aacb9cf645a86bfeb
```

These hashes identify the **10-8-2026 build**. Repacked archives need not match the release EXE hash; compare the exact extracted payload and manifest inventories.
