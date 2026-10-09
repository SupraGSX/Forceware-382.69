Forceware 382.69 - custom NVIDIA Windows XP 32-bit driver
Build: 10-9-2026 (display INF date: 10/09/2026)

Launch Forceware 382.69 (10-9-2026).exe and follow the NVIDIA installer.
When upgrading, select Custom (Advanced), Perform a clean installation,
then restart. Alternatively, extract the package and run setup.exe.
This is a modified, unsigned 368.81-based package, not an official NVIDIA release.
Windows Server 2003 x86 is supported with optional GeForce Experience omitted.

Includes Pascal initialization, Direct3D/OpenGL/compute updates, DisplayPort
and HDMI handling, and integrated Customize, Scaling, Overscan and topology
pages. Bundled HD Audio, PhysX and nView retain their existing versions.

GP107 desktop support is included: GTX 1050/1050 Ti and Quadro
P400/P600/P620/P1000. GTX 1050 Ti was hardware tested; the other GP107 models
were not individually tested. GP107 defaults to HBR2 or lower DisplayPort
rates. HBR3 output remains unresolved on the tested GTX 1050 Ti.
Mobile, GP100 and GP108 GPUs remain excluded.

See Documentation/Forceware-382.69.md for features and compatibility limits,
Documentation/GP107-support.md for GP107 implementation and testing, and
ListDevices.txt for the full Maxwell/Pascal INF list.
