# Changelog

## v1.1
- Double tap works right after boot. Before, it only started after the screen had been turned on and off once.
- The driver now loads early in boot instead of after Android starts.
- Experimental support for other Odin 2 family devices: finds the touchscreen automatically and stamps the driver for your kernel, falling back to stock if it doesn't fit.
- Crash guard: if a driver load ever doesn't finish, the module disables itself on the next boot.
- Added `compat-check.sh`, a read-only check you can run and share.

## v1.0
- First release. Double tap to wake for the Odin 2 Portal on firmware V1.0.0.338.
- Falls back to the stock touch driver on unsupported kernels or if the driver fails to load.
- Works with Magisk, KernelSU and APatch.
