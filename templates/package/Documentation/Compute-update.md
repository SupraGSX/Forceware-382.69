# CUDA, OpenCL and GPU PhysX update

Build: 10-5-2026.

The driver could install and render Direct3D while CUDA and OpenCL failed to enumerate the GPU and PhysX fell back to the CPU. On GTX 1080 Ti, the shared failure was the driver's internal GPU short-name query: the stock table lacked PCI device ID 1B06. The display INF name does not supply this internal name.

The corrected miniport preserves all 640 original records and adds ten missing GPU names: 1B02, 1B06, 1B83, 1C04, 1C06, 1C31, 1C83, 1CB1, 1CB2 and 1CB3. Seven table references, three search bounds and the required relocation entries are updated. No device identity, capability flags, firmware authentication or error returns are bypassed.

Internal records include GP107 for continued development. This unstable Test 2 restores the GP107 display INF entries for diagnosis despite earlier Code 10 reports. Retaining these names, experimental code and PhysX installer entries does not establish working GP107 initialization.

The underlying correction passed CUDA context creation, an OpenCL GPU kernel with 8,192 checked results, GPU PhysX FluidMark execution, and hardware Direct3D 9 checks on GTX 1080 Ti. Offline native execution checked 4,872 short/long lookups across the original table and the expanded table at preferred and relocated addresses. Other GPUs were not individually hardware-tested.

The existing CUDA, OpenCL and PhysX implementations are retained. Build-identification metadata is dated October 5, 2026; this does not claim a new compiler or CUDA/OpenCL API version.
