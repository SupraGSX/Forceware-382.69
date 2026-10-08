Forceware 382.69 - custom NVIDIA Windows XP 32-bit driver
Build: 10-8-2026 (display INF date: 10/08/2026)

Launch Forceware 382.69 (10-8-2026).exe, follow the normal NVIDIA installer, and restart.
Alternatively, extract the package and run setup.exe.
When upgrading an earlier 382.69 build, choose Custom (Advanced), select
Perform a clean installation, and restart to replace all display files.
This is a modified, unsigned 368.81-based package, not an official NVIDIA release.

Includes Pascal initialization/3D, the OpenGL display-class fix,
and internal GPU-name corrections for CUDA, OpenCL and GPU PhysX,
improved DisplayPort link/depth selection,
HDMI identification/SCDC/clock-limit and setup recovery fixes, and integrated
Control Panel Customize, DisplayPort scaling and topology/EDID support.
No separate add-on is required.

Mobile, GP100, GP107 and GP108 GPUs are excluded from the display INF.
See Documentation/Forceware-382.69.md for features and compatibility limits.

GP107 display INF entries are withheld following reported Code 10 failures.
Experimental GP107 initialization and internal name records remain in the binary.

This build also adds Server 2003 x86 installer compatibility and DisplayPort
startup and display-sleep recovery fixes. GeForce Experience is omitted on
Server 2003; Windows XP retains its existing requirements.

October 8: improved HDMI vendor-block handling, separate Scaling and Overscan
pages, and automatic native HDMI/DisplayPort scaling. Overscan resizing remains
subject to native timing support.

Automatic DisplayPort scaling preserves matching preferred-timing refresh
and checks trained-link bandwidth. It does not force maximum refresh.
