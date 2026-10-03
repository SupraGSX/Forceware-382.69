# HDMI SCDC setup recovery

This increment belongs in both display-driver binaries. It uses no resident utility, EDID override or host intervention in normal operation. It retains the prior Pascal, DisplayPort training/depth, HDMI identity/clock and Control Panel fixes.

## Setup transaction

The stock miniport `6E3020` reads SCDC and writes TMDS_CONFIG but discards I2C status. The observed mode worker also ignores its return. Returning an error from that routine alone cannot recover the display.

The paired implementation arms a transaction immediately before the display DLL commits a high-clock HDMI mode in `48DD0`. The guard requires positive source/sink HDMI identity from the existing `47990` query and a physical clock above 340 MHz. A private extension of RM control `730293` resolves the existing GPU and TMDS connector; exact command values are intercepted at `79C502` before any legacy capability mutations. Ordinary commands retain their stock behavior.

An owned 32-entry table in the miniport's appended section holds GPU/connector identity, generation and setup-write outcome. It uses an atomic non-blocking lock; there is no borrowed padding in an undocumented NVIDIA object. A mode-local flag in the display routine records that this invocation actually armed a transaction. Common cleanup consumes it even on an existing error edge and clears it before returning a Boolean.

The `6E3171` hook calls the existing I2C write callback with the same arguments. For an armed high-rate setup, it allows at most three write attempts, with the native two-millisecond delay between failed attempts. A successful acknowledgement is latched for this transaction. Later status-read failures are not consulted. After a successful setup, later write failures in the same transaction do not erase that success. Outside a transaction, the original single-write behavior is retained.

Cleanup at `49892` checks the transaction result. Missing successful setup changes the mode result to failure. The `49C35` hook propagates failure into the containing mode-enable operation instead of discarding it. In the tested XP path, Windows responds by enabling a safe 640x480 mode. This is a safe-mode fallback, not a guarantee of restoring the exact previous resolution.

## ABI and scope

All addresses are preferred virtual addresses at image base 10000. The output-clock field used by the display guard is in 10 kHz units; the native 340000 kHz comparison at miniport `6E3140` remains unchanged. The new code neither raises clock ceilings nor changes DVI dual-link policy, color depth or DisplayPort policy. ARM/END commands bypass the legacy sink-capability setters. The native I2C read remains unchanged; a failed later read cannot invalidate a successful configuration write.

The normal build uses FAULT=0. Separate diagnostic miniports simulate all three writes failing, or two transient failures followed by a real write. These diagnostics are excluded from the installer. Exact input hashes, displaced instructions, append boundaries, PE sizes/checksums and output hashes are recorded in the repository's patch manifest and source.

## Nouveau reference

Linux/Nouveau commit `adc218676eef25575469234709c2d87185ca223a`, paths `drivers/gpu/drm/nouveau/nvkm/engine/disp/gm200.c`, `gp100.c`, `gp102.c`, and `drivers/gpu/drm/nouveau/dispnv50/disp.c`, supplies the Maxwell/Pascal HDMI/SCDC comparison. GP104/GP102 use the shared GM200 HDMI/SCDC implementation through the Pascal SOR definitions. Its 340 MHz configuration transition and source scrambling/clock-ratio bits agree with the independently traced Windows behavior. The Linux host routine logs a failed write and can continue to source programming; it is not a ready-made recovery implementation. No Linux object layout or recovery code was copied into XP. The previously inspected Mesa compiler revision `f1f246cfda65eff82fba3be1caf2d23bdeda60cc` is unchanged; this patch changes no shader/compiler behavior.

## Limits

The fault tests establish this mode-enable path on a GTX 980 Ti and AW3423DW, not every hotplug, resume, alternate mode-update path, GPU or monitor. A permanently disconnected/unresponsive receiver cannot be forced to display by software. Receiver read failures observed after an established good picture remain unexplained. NVAPI TryCustomDisplay can return success when Windows has substituted 640x480; applications must inspect the actual resulting mode. This increment does not claim to change that native reporting behavior.
