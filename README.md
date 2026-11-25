# Odin 2 Portal Double Tap to Wake

A Magisk module that lets you wake the AYN Odin 2 Portal by double tapping the screen, like most phones (and the Retroid Pocket Nova) do.

The Portal ships with the touchscreen's gesture support turned off, so the "double tap to wake" setting in Android doesn't do anything. This module swaps in a touch driver that keeps listening while the screen is off, plus a small script that wakes the screen when it sees two quick taps.

## Requirements

- **Verified:** AYN Odin 2 Portal on firmware **V1.0.0.338**
- **Experimental:** other Odin 2 family devices (Odin 2, Mini, Max) and other Portal firmware. It'll try, and fall back to the stock touch driver if anything doesn't fit. Please report how it goes.
- Root with Magisk, KernelSU or APatch

Doesn't apply to the Odin 3 (different chip and kernel); the module won't install there.

## Check your device first (optional)

`compat-check.sh` is read-only and tells you whether your device looks compatible. Run it as root, in Termux or over adb:

```
su -c sh compat-check.sh
```

Paste the output in an issue (or the Reddit thread) along with whether double tap worked.

## Install

1. Download `odin2-portal-dt2w.zip` from [Releases](https://github.com/jevonlipsey/odin2-portal-dt2w/releases/latest).
2. Magisk > Modules > Install from storage, pick the zip.
3. Reboot.

It's ready by the time the lock screen shows up. Turn the screen off and double tap.

## What to expect

- Two quick taps wake the screen. A single tap, a long press, or your hand resting on it won't.
- Touch works exactly like normal while the screen is on.
- If something doesn't match (different firmware, different touch hardware, driver won't load), the module puts the stock driver back and touch keeps working normally. You just won't have double tap.
- If a load attempt ever crashes or gets interrupted, the module turns itself off on the next boot and leaves stock touch alone. Re-enable it in Magisk if you want to try again.
- The touchscreen stays powered while the screen is off. In practice the battery difference is tiny.
- The touch firmware is never updated or flashed.

## Uninstall

Disable or remove the module in Magisk and reboot. The stock driver loads like before.

## Troubleshooting

Check `/data/adb/modules/odin2portal_dt2w/dt2w.log`, or run `compat-check.sh` (it prints the log too). Open an issue with that output if something's off.

## How it works

The Portal's touch controller is the same FocalTech part the Nova uses. The module loads the Nova's build of that driver, which has gesture support built in, with a few changes:

- stamped with your kernel's version at boot, so the kernel itself checks whether it's compatible
- its built-in touch firmware updater is disabled, so it never flashes the Nova's touch firmware onto the Portal
- since the Portal's touch firmware can't recognise gestures itself, every touch while the screen is off is passed up as a harmless key, and `dt2w-daemon.sh` decides when two taps are a double tap

`post-fs-data.sh` swaps the driver in early in boot, checks that the touchscreen came back, and falls back to stock if it didn't. `service.sh` starts the double tap script once Android is up.
