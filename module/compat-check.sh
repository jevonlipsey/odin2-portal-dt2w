#!/system/bin/sh
# Odin double tap to wake: compatibility check. Read-only, changes nothing.
# Run as root:  su -c sh compat-check.sh   (Termux, or adb shell)
# Paste the whole output when you report results.

[ "$(id -u)" = 0 ] || echo "(not running as root, some lines will be missing)"
echo "=== odin dt2w compat check ==="
echo "device:   $(getprop ro.product.manufacturer) $(getprop ro.product.model) [$(getprop ro.product.device), $(getprop ro.board.platform)]"
echo "firmware: $(getprop ro.build.display.id)"
echo "android:  $(getprop ro.build.version.release)"
echo "kernel:   $(uname -r)"

tp=""; for d in /sys/bus/i2c/drivers/fts_ts/*-*; do [ -e "$d" ] && { tp=/sys/bus/i2c/devices/${d##*/}; break; }; done
other=""
for drv in NVT-ts gtx8_i2c goodix-ts goodix_ts synaptics_tcm_i2c atmel_mxt_ts himax_tp ilitek_ts; do
  ls -d /sys/bus/i2c/drivers/$drv/*-* >/dev/null 2>&1 && other="$other $drv"
done

chip=""
if [ -n "$tp" ]; then
  chip=$(grep -o 'IC ID:0x[0-9a-fA-F]*' $tp/fts_driver_info 2>/dev/null | cut -d: -f2)
  echo "touch:    FocalTech on ${tp##*/}, chip ${chip:-unknown}, fw $(cat $tp/fts_fw_version 2>/dev/null | head -1)"
  [ -e $tp/fts_gesture_mode ] && echo "gesture:  $(head -1 $tp/fts_gesture_mode) (gesture driver is loaded)" || echo "gesture:  not available in the current driver"
else
  echo "touch:    no FocalTech touchscreen${other:+ (found:$other)}"
fi

stock=""; for p in /vendor_dlkm/lib/modules /vendor/lib/modules /system_dlkm/lib/modules; do [ -f $p/focaltech_fts.ko ] && { stock=$p/focaltech_fts.ko; break; }; done
[ -n "$stock" ] && echo "driver:   $stock, vermagic: $(/system/bin/modinfo -F vermagic $stock 2>/dev/null)"

[ -f /data/adb/modules/odin2portal_dt2w/dt2w.log ] && { echo "--- module log ---"; cat /data/adb/modules/odin2portal_dt2w/dt2w.log | grep -v '^$' | tail -15; }

echo "--- verdict ---"
case "$(uname -r)" in
  5.15.*) k=ok ;;
  *) k=no ;;
esac
if [ "$k" = no ]; then echo "won't work: different kernel generation, the driver can't load here"
elif [ -z "$tp" ]; then echo "won't work: this device uses a different touch controller${other:+ ($other)}"
elif [ "$chip" != "0x5452" ]; then echo "probably won't work: different FocalTech chip (${chip:-unknown}); safe to try, it falls back to stock"
elif [ "$(uname -r)" = "5.15.123-android13-8-g94ea6c79c823" ]; then echo "verified: this is the setup it was built and tested on"
else echo "good candidate: same touch chip, untested firmware. Install it, reboot, and report back"
fi
