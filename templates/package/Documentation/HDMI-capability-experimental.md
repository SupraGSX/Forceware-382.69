# HDMI capability policy — Release Candidate

This revision retains all Pascal firmware changes from Experimental Pascal Firmware Test 1 and adds a die-specific HDMI policy covering all existing display INF entries.

| GPU family | Conservative source-policy ceiling | Legacy 165 MHz correction |
|---|---|---|
| Fermi | 225 MHz | Disabled pending evidence |
| Kepler / first-generation Maxwell | 297 MHz | Experimental |
| Maxwell 2 / Pascal | 594 MHz | Existing policy retained |

Limits are TMDS character rates, not unconditional pixel-clock unlocks. Monitor declarations and non-default native source/board limits remain effective. Older GPUs do not acquire HDMI 2.0 scrambling capabilities from an HDMI 2.0 monitor. Unknown dies cannot override the 165 MHz default. Existing HDMI/DVI separation and DisplayPort handling are retained. Elevated HDMI limits are advertised only after the receiver update and readback succeed; source-query units and board-limit arithmetic are checked.

The older-generation bounds are conservative policy values, not measured maximum rates for every board. A 165 MHz restriction on an untested board may represent a real limitation; the Kepler/Maxwell 1 correction therefore needs physical testing. Modes requiring more than 297 MHz remain outside this experimental older-card policy.

Offline checks passed for the HDMI policy and failure-path matrix, malformed EDID handling, all INF mappings, compiled capability lookups and firmware selectors at preferred and relocated addresses. The combined candidate was hardware tested on GTX 1050 Ti over HDMI; older-GPU HDMI operation remains unverified. Keep the stable installer for rollback and use a recoverable clean installation.
