# October 17 experimental update

Core PMU receive/IRQ ownership and Falcon memory-transfer protections are now
selected per Pascal adapter. Older GPU routes retain the original 368.81
operations. GP108 retains its clock/power/completion adapters and uses a private
engine allocation for their additional state. Shared stock firmware descriptors
are preserved; Pascal registration selects its required matched resources.
OpenGL uses the original display-class list unless the native RM list advertises
Pascal display class 9870. Existing DisplayPort, HDMI, audio, scaling and Control
Panel improvements and installer corrections remain included.

This is not a claim that the original intermittent hardware hangs are eliminated.
Use Custom (Advanced), Perform a clean installation, then restart.

Repackages the October 15 driver with October 17 build identification.
Driver binary behavior is unchanged from that tested build. Original 368.81 notebook/OEM INF files and missing main-INF device entries are restored, with the current package version, date and coinstaller names.
