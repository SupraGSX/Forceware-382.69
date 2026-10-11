# Pascal firmware — Release Candidate

Forceware 382.69 (10-11-2026). Release candidate based on the October 9 stable release.

This is **not the stable driver**. It updates graphics firmware independently for each Pascal family:

| Chip | Firmware donor |
|---|---|
| GP102 | GeForce 381.65 |
| GP104 | GeForce 398.11 |
| GP106 | Quadro 431.02 |
| GP107 | Quadro 390.77 |

Updates include matched family-specific FECS/GPCCS boot loaders, boot headers, signatures and graphics bundles. Signed firmware instructions remain intact. Existing XP callbacks, secure-loading fixes, display handling and supported desktop device entries are retained. GP100 and GP108 remain excluded.

The GP107 390.77 set previously passed testing on a GTX 1050 Ti in a separate experiment. The combined installer subsequently passed clean installation, Direct3D and OpenGL on GTX 1050 Ti, including all eleven GPU Caps Viewer 1.37.0 demos in bounded runs. GP102/GP104/GP106 firmware replacements have **not been hardware validated**. Other board variants, including P620 and P2200, remain unverified. A newer payload alone does not prove that it is required or backward compatible. The XP archive reader can resolve every entry in these newer archives; GPU authentication, context handling and runtime compatibility still require physical tests for each untested family.

## Installation and testing

Use a recoverable test installation. Run the EXE, select **Custom (Advanced) → Perform a clean installation**, then restart. Keep the October 9 stable installer available for rollback.

Report the GPU model, PCI device ID, this exact build title, installation result and any startup or rendering failures. Validate display output, Direct3D, OpenGL, CUDA, OpenCL, GPU PhysX and display sleep/wake before relying on this build.

This revision also includes the experimental table-driven HDMI policy. See [HDMI changes and limits](HDMI-capability-experimental.md).
