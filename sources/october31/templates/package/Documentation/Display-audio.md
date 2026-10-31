# Display audio — October 12, 2026

This build improves DisplayPort and HDMI audio discovery and includes the HD
Audio INF correction in the normal installer.

Audio capabilities are collected from valid CTA blocks throughout the EDID,
including CTA collections inside DisplayID. Distinct audio descriptors remain
separate and are filtered against the existing source and timing limits.
Malformed or incomplete data is rejected. HDMI identity remains required for
HDMI audio; missing audio capability clears the endpoint.

The implementation uses a bounded 2048-byte EDID snapshot and supports up to
15 distinct ELD audio descriptors. This is an implementation limit, not the
EDID specification maximum. Overflow is rejected rather than advertising an
arbitrary subset. Extended audio-format code 15 is not newly enabled. Raw EDID
API size remains unchanged. Existing GPU, monitor, HDMI and DVI limits remain
in force.

Validated in Windows XP SP3 on GTX 1050 Ti: native DisplayPort audio detection,
HDMI test EDIDs covering nested and multiple audio blocks, legacy basic audio,
missing identity and invalid nested checksums; DirectSound, playback-buffer
completion, Direct3D and OpenGL. Audible output, physical hotplug and other GPU
models were not verified in this validation.

For an upgrade, choose Custom (Advanced), Perform a clean installation, and
restart. Install the full package to keep the display-driver pair and HD Audio
binding together. Bundled HD Audio, PhysX and nView versions are unchanged.
