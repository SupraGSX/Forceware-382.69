# Display audio and HDMI capability projection

October 12 continues the October 11 rollback without newer graphics firmware.
The patch manifest reconstructs the exact final bytes from the same NVIDIA
inputs; `verify_display_audio.py` independently compiles these sources and
checks every hook against the resulting paired driver modules.

- `legacy-edid-length.s`: reports the first available extension within the native
  copy length. It leaves the raw EDID API's 256-byte maximum unchanged.
- `edid-blocks.c/.h`: validates a maximum 2048-byte EDID snapshot, CTA blocks and
  DisplayID-contained CTA collections. It retains up to 15 distinct audio
  descriptors; malformed, incomplete or overflowing audio data fails closed.
- `audio-mini.c/.s`: obtains the snapshot through the existing RM request,
  projects audio for discovery/ELD consumers, preserves native transport and
  timing-budget checks, and refreshes HDMI identity without replacing the raw
  EDID or rearranging video timings.
- `audio-disp.c/.s`: bounds descriptor consumption and clears stale ELD validity
  on failed construction while preserving the native enable intent and cleanup.
- `hdmi-policy.c` and `hdmi-hooks.s`: retain the existing rollback GPU-family and
  HDMI/DVI policy, using validated complete-cache HDMI capabilities. Missing or
  conflicting identity cannot authorize elevated clocks. SCDC setup/readback and
  source/monitor restrictions remain required.
- `mini.ld`, `disp.ld`, and `hooks.json`: document the XP 368.81 callback addresses,
  append locations, guarded original instructions and replacement branches.

The first standalone CTA keeps its native video/auxiliary projection. Later
collections contribute audio and HDMI capabilities only. Additional blocks do
not manufacture HDMI identity, audio support or arbitrary video modes. Extended
SAD format code 15 is not newly enabled. The code uses a per-call nonpaged
allocation and adds no shared mutable state or new locking.

Compile and compare with:

```bash
python3 verify_display_audio.py --package "build-38269/Forceware 382.69" --out audio-check
```

The compiler settings are pinned in that script (GCC freestanding i386, `-Os`,
no absolute data references/GOT). Matching instruction bytes is an offline
reconstruction check; see the main rebuilding guide for runtime validation.
