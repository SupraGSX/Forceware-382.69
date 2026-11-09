Forceware 382.69 - custom NVIDIA Windows XP 32-bit driver
Build: 11-9-2026 (display INF date: 11/09/2026)

Run the EXE, or extract it and run setup.exe.
When upgrading, select Custom (Advanced), Perform a clean installation,
then restart. Reselect the primary monitor in Windows Display Properties
if needed. Keep a known-working installer for rollback through Safe Mode.

This is a modified, unsigned 368.81-based package, not an official NVIDIA
release. Windows Server 2003 x86 is supported; optional GeForce Experience
is omitted there. HD Audio, PhysX and nView retain their existing versions.

Includes GT 1030 GDDR5/DDR4 handling, GP107/GP108 runtime corrections,
rendering/compute fixes, DisplayPort HBR2/HBR3, HDMI clock and scaling
handling, and Customize, Scaling, Overscan and topology pages.
GP107 is no longer restricted to HBR2. Link rates depend on actual
hardware capabilities and successful training.

November 9 hardware validation was reported on M4000, GTX 1050 Ti,
GT 640 and both GDDR5 and DDR4 GT 1030. Other individual models and
long-run stability remain subject to testing. INF inclusion alone is not
proof of model compatibility. Original 368.81 notebook/OEM entries remain;
new models are desktop-only. GP100 and GP108 models other than GT 1030
device 1D01 remain excluded.

See BUILD-NOTES.txt for changes, Documentation/Forceware-382.69.md for
features and limits, and ListDevices.txt for the additional device list.
Optional GeForce Experience is offered on eligible XP SP3 systems;
full application operation has not been verified.
