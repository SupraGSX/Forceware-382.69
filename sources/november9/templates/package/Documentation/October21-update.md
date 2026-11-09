# October 21 update

- Updates GP107 firmware and initialization for Quadro P620 compatibility, with corrected clock, power and telemetry handling.
- Improves display-profile and sleep/resume handling.
- Includes High Clock v2 HDMI handling for Fermi, Kepler and first-generation Maxwell cards, subject to monitor and hardware limits.

When upgrading, select **Custom (Advanced) → Perform a clean installation**, then restart.

GTX 1050 Ti regression testing includes Direct3D, OpenGL, CUDA, OpenCL, GPU PhysX, games and sleep/resume. Quadro P620 passed earlier stages; final changes have offline P620 coverage and await another hardware check. This does not establish complete 391.35 parity or eliminate every intermittent hardware hang.
