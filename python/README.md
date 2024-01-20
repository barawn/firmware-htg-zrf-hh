# PYNQ python sources for HTG builds

Basic source to verify working HTG setup. You need to program the
Si5341 clock externally to get the board working first.

This build includes a DebugBridge for Ethernet debugging. Make
sure you stop the XVC server before exiting Python.

```
from htgadc import htgADC
htg = htgADC()
dbg = htg.debug_bridge_0
dbg.start_xvc_server()
# do things here
dbg.stop_xvc_server()
```
