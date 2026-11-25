# Odin 2 Portal Double Tap to Wake

A Magisk module that lets you wake the AYN Odin 2 Portal by double tapping the screen, like most phones (and the Retroid Pocket Nova) do.

The Portal ships with the touchscreen's gesture support turned off, so the "double tap to wake" setting in Android doesn't do anything. This module swaps in a touch driver that keeps listening while the screen is off, plus a small script that wakes the screen when it sees two quick taps.

## Requirements

- AYN Odin 2 Portal
- Firmware **V1.0.0.338** (Settings > About). Other versions stay on the stock driver until they're tested.
- Root with Magisk, KernelSU or APatch

## Install

1. Download `odin2-portal-dt2w.zip` from [Releases](https://github.com/jevonlipsey/odin2-portal-dt2w/releases/latest).
2. Magisk > Modules > Install from storage, pick the zip.
3. Reboot.

Give it about 15 seconds after the lock screen shows up, then turn the screen off and double tap.

## What to expect

- Two quick taps wake the screen. A single tap, a long press, or your hand resting on it won't.
- Touch works exactly like normal while the screen is on.
- If something doesn't match (different firmware, driver won't load), the module puts the stock driver back and touch keeps working normally. You just won't have double tap.
- The touchscreen stays powered while the screen is off. In practice the battery difference is tiny.
- The touch firmware is never updated or flashed.

## Uninstall

Disable or remove the module in Magisk and reboot. The stock driver loads like before.

## Troubleshooting

Check `/data/adb/modules/odin2portal_dt2w/dt2w.log`. If it says the kernel isn't supported, your firmware version hasn't been tested yet. Open an issue with your firmware version and `uname -r`.

## How it works

The Portal's touch controller is the same FocalTech part the Nova uses. The module loads the Nova's build of that driver, which has gesture support built in, with a few changes:

- set up for the Portal's kernel
- its built-in touch firmware updater is disabled, so it never flashes the Nova's touch firmware onto the Portal
- since the Portal's touch firmware can't recognise gestures itself, every touch while the screen is off is passed up as a harmless key, and `dt2w-daemon.sh` decides when two taps are a double tap

`service.sh` loads it after boot, checks that the touchscreen came back, and falls back to stock if it didn't.
