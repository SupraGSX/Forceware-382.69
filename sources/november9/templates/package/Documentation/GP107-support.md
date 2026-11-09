# GP107 desktop support

The driver includes GTX 1050 (1C81/1C83), GTX 1050 Ti (1C82), Quadro P1000
(1CB1), P600 (1CB2), P400 (1CB3) and P620 (1CB6). GTX 1050 Ti has current
hardware validation. P620 passed earlier integration tests; the latest
changes await requalification on that card. Other GP107 models are not
individually qualified. Original stock notebook/OEM entries remain, but
additional GP107 models are desktop-only.

The active 391.35 firmware path uses XP-specific request, completion,
clock, voltage, power-management and state-layout adapters. Initialization
errors remain errors. Native PMU worker ownership and the legacy-GPU boot
repair are retained. Runtime corrections shared with GP108 are applied
through adapter-specific guards.

GP107 permits HBR3 as well as HBR2 and lower DisplayPort rates, with real
training, receiver checks and bandwidth/depth selection. GTX 1050 Ti was
confirmed at 3440x1440/175 Hz, HBR3 x4, RGB 8-bit. This is not a guarantee
for every card/cable/sink and does not establish DSC, HDR or MST support.

GTX 1050 Ti testing has covered Direct3D, OpenGL, CUDA, OpenCL, GPU PhysX,
HDMI/DisplayPort output and sleep/resume. Enable GPU PhysX in both NVIDIA
Control Panel and the application; start a fresh process after changing
that selection. No bounded test establishes universal or long-run stability.
