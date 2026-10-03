# Trained DisplayPort link policy

This increment applies to the custom Forceware 382.69 XP32 binaries. It retains the Pascal, HDMI, topology and version fixes. The Control Panel includes the corrected digital-output classification and scaling-cache refresh.

## Policy

The receiver's advertised maximum is an upper bound, not proof that the GPU can use it. Miniport output+0x2D00 records each successful automatic training attempt. The new query adapter intersects those results with receiver rate/lane limits and exports one matched pair with the greatest payload capacity. It never combines independently derived rate and lane maxima. Empty results export 0/0.

The display driver's selector uses that pair directly, instead of choosing an unrecorded lower pair from its old static table. RGB payload calculation includes the existing 0.5% margin and 8b/10b link coding. It retains the requested 6/8/10/12/16-bit depth if it fits, otherwise reduces a higher depth to 8 bits if that fits. A timing that cannot fit is rejected. Overflow and unknown depth codes fail closed. The ordinary mode path returns through its existing failure cleanup; the secondary void DP escape helper exits without its old guessed-link fallback.

The existing automatic training table supplies RBR and HBR at 1/2/4 lanes, plus HBR2 and HBR3 at 4 lanes. This increment does not invent success for HBR2/HBR3 at 1/2 lanes or add those table entries. A subsequently changed cable/sink can still fail retraining: a prior successful probe is evidence, not a permanent electrical guarantee. The original hardware training/error handling remains in place.

## Exact hooks

Addresses are preferred virtual addresses, image base 0x10000. All new calls/jumps are relative; no PE relocation records are added or removed.

| Binary | Hook | Function |
|---|---|---|
| nv4_mini.sys | 0x44C737, 18 bytes | Return rate and lanes from the same successful training entry |
| nv4_disp.dll | 0x47E50, 6 bytes | Replace static pair guessing with paired bandwidth validation |
| nv4_disp.dll | 0x492A9, 6 bytes | Depth selection and early failure cleanup |
| nv4_disp.dll | 0x492E5, 5 bytes | Reject selector failure before default-link fallback |
| nv4_disp.dll | 0x4A0E8, 8 bytes | Remove fallback from secondary void DP escape path |

The repository's `rebuild.py` validates exact vendor inputs and displaced bytes, then verifies complete output hashes. `verify_sources.py` compiles the added code and compares the inserted blocks. The final executable section is extended and PE sizes/checksums are updated without changing data directories. `sources/dp-trained/dp-policy.c` has no runtime library dependencies.

## Diagnostic builds

Normal retains training preference 0x65432178. HBR diagnostic uses original 0x654321. RBR diagnostic uses 0x642 (table IDs 2,4,6). They limit real training attempts; they do not forge receiver data or success bits. Only normal is intended for distribution.

## Nouveau findings

Linux commit `adc218676eef25575469234709c2d87185ca223a`:

- `drivers/gpu/drm/nouveau/nvkm/engine/disp/dp.c`: `nvkm_dp_train_links` programs the source and `nvkm_dp_train_link` separately configures the sink, checks clock recovery and channel equalization, then reports success/failure.
- `drivers/gpu/drm/nouveau/nvkm/engine/disp/gm200.c`: GM200 DP callbacks share `gf119_sor_dp_links`, with GM200 drive configuration.
- `drivers/gpu/drm/nouveau/nvkm/engine/disp/gp100.c` and `gp102.c`: Pascal SOR paths reuse GM200/GF119 functionality; that does not imply identical Windows callbacks or private layouts. In this Windows build the observed GM200 callbacks differ from the previously traced Pascal callback.

The implication is to distinguish advertised sink limits, attempted source programming and completed training. Source SOR readback plus receiver DPCD status corroborate successful runtime tests. The NVIDIA private bitmap/layout was established independently through the Windows traces. No Linux structures or code were transplanted. Graphics/shader/compiler paths are unchanged by this increment; the earlier GM200/GP104/GP102 and Mesa analysis remains applicable.

## Validation status

The new normal build has user-confirmed normal 3440x1440/100 output on GTX980Ti/AW3423DW, HBR2x4, RGB10, with 64 D3D9 hardware shader draw/readbacks passing. The HBR-limited build has user-confirmed normal native 3440x1440/60 output at RGB8, and rejects 3440x1440/100 without leaving the supported 1024x768 desktop. The RBR-limited build has user-confirmed normal standard 1080p/59.94 output at RGB10, also passing all 64 hardware draw/readbacks. The RBR build rejects native 3440x1440/60 and retains 1024x768. Every bounded test returned safely without a VM reset. This is not a claim that a DP1.1 GPU, every board/sink or all DP1.4 features have been tested.
