# GT 1030 / GP108 support

The October 13 build adds GeForce GT 1030 device 1D01 to the display INF.
It retains the October 12 display-audio, Control Panel and installation changes.

GP108 uses matched NVIDIA 382.23 PMU, ACR, graphics, SEC2 and display firmware
resources. SEC2 selection follows the resource tuple actually loaded by the
supported Windows driver; its image, descriptor and signature remain matched.
The XP host code translates queue descriptors, display snapshots, copy-engine
setup and power/clock commands into the formats required by those resources.
Signed firmware and authentication are preserved. Other GPU families retain
their previous firmware and behavior.

Direct3D, OpenGL, CUDA, OpenCL and GPU PhysX passed bounded tests on a GT 1030
GDDR5 card. Automatic boost, return to idle and ordinary reboot also passed.
These results do not qualify every GP108 board or memory variant. Fan/voltage
telemetry and additional power-policy paths remain incompletely validated.

Install the whole package using Custom (Advanced), Perform a clean installation,
then restart. Do not combine individual files from different builds.

October 14 corrects GP108 clock-gating init/set command translation, waits for actual disable completion, and applies BIOS per-performance-state power-gating restrictions. These changes address verified host/firmware handling gaps; the intermittent GPU hang remains under investigation. Earlier bounded rendering results do not establish sustained stability.
