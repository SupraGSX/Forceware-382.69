# GP107 Test 2 — experimental / unstable

Based on **Forceware 382.69 (10-5-2026)**. Previous GP107 builds still produced Code 10 for testers. This release tests one capability-flag hypothesis and is not a confirmed fix.

## Change

The GP107 callback first calls XP's original GP104 capability initializer, which sets byte `+0x62D` to `1`. The previous experimental code then cleared that byte to `0`, using an inferred correspondence with the newer driver. Test 2 changes the explicit write to `1`, preserving the inherited value. Removing that write would leave the same flag state.

Only this instruction operand and the required PE checksum change in `nv4_mini.sys` relative to the October 5 stable binary. No firmware, memory-security checks, graphics-context constants, resource selectors, internal GPU-name tables or other runtime modules change. The meaning of the flag and its effect on GP107 hardware remain unverified.

Restored desktop INF IDs: GTX 1050 (`1C81`, `1C83`), GTX 1050 Ti (`1C82`), Quadro P1000 (`1CB1`), P600 (`1CB2`), P400 (`1CB3`) and P620 (`1CB6`). Mobile, GP100 and GP108 remain excluded. Internal compute records and the PhysX installer GPU list are unchanged.

## Test procedure

1. Keep a recoverable XP installation and the previous driver available. Use the GP107 card as the primary display GPU; for passthrough, it must be the VM's primary VGA device.
2. Run this experimental installer. For any existing driver installation, choose **Custom (Advanced) → Perform a clean installation**, then restart.
3. Confirm the installed `WINDOWS/system32/drivers/nv4_mini.sys` SHA-256 is `98876708f9d31ae410608a2edbc89166cfd8a33aaed68a5c7ccf8598e3155bc7`. The display version remains 6.14.13.8269 and date October 5, 2026, so the hash distinguishes this experiment from stable.
4. Report the exact GPU model/PCI ID and Device Manager status. If it starts, check dxdiag DirectDraw/Direct3D acceleration, then OpenGL and normal applications. If it still fails, record Code 10 or any changed symptom; do not infer the failed initialization stage from Code 10 alone.
5. If necessary, return to Safe Mode and roll back the driver.

The October 5 stable base passed installation, CUDA, OpenCL, Direct3D, OpenGL and GPU PhysX checks on GTX 1080 Ti. Those results do not validate this GP107 change. This experimental installer has no GP107 hardware pass. The patched miniport passed 166 offline execution checks at its preferred and relocated addresses, covering registration, constructors, the enabled flag, resource pointers and GP106 preservation. Those checks do not execute a GPU, firmware or the Windows kernel. Source-to-binary checks separately verify the assembled instruction bytes.

The earlier GP107 implementation, matched donor resources and source references are described in `REBUILDING.md`. Nouveau and Mesa guided the earlier comparison; private Linux and Windows object layouts are not assumed identical.
