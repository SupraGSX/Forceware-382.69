# GT 1030 / GP108 support

GT 1030 device 1D01 is included. Both GDDR5 and DDR4 cards have hardware
validation; other GP108 model IDs are not added by this package.

The active GP108 path uses matched 391.35 firmware with XP-specific adapters
for initialization, queues, display state, copy-engine setup, clock, voltage,
power-management and completion handling. Firmware authentication is retained.

November 9 corrects missing DDR4 memory-clock operations: clock-drive
configuration, QUSE DLL updates and non-training write-barrel-shifter updates.
The latter uses the selected timing's value and preserves the two non-flushing
waits. It is guarded for the supported single-partition DDR4 path; GDDR5 and
other GPU families retain their existing paths.

The repaired DDR4 GT 1030 passed a clean installation and reboot, normal
3440x1440 HDMI output, and six checked GDI/Direct3D/OpenGL rendering and
application-relaunch cycles without a captured bugcheck. GDDR5 control testing
also covered CUDA/OpenCL results, power transitions and targeted failed-start
cleanup. The release has additional user-reported validation on both memory
variants. These are bounded results, not a guarantee for every board or of
long-run stability.

Use Custom (Advanced), Perform a clean installation, then restart. Do not
combine individual driver files from different builds.
