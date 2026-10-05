Forceware 382.69 - GP107 Test 2 (Experimental)
EXPERIMENTAL / UNSTABLE — GP107 hardware startup is unverified.
Display INF date: 10/05/2026; display version: 6.14.13.8269.

Based on the October 5 stable driver with its existing fixes. This test changes
one GP107 capability flag from 0 to 1 and restores seven GP107 display INF IDs.
Previous builds still returned Code 10. This is not a confirmed fix.

Launch this EXE, or extract it and run setup.exe. When updating any existing
driver installation, choose Custom (Advanced), select Perform a clean
installation, and restart. Keep a recovery route and the previous driver.

Use the GP107 card as the primary display GPU. See
Documentation/GP107-experimental.md for the expected miniport hash and tests.
Mobile, GP100 and GP108 GPUs remain excluded.
This is a modified, unsigned 368.81-based package, not an official NVIDIA release.
