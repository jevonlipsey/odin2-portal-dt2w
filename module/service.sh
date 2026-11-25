#!/system/bin/sh
# Starts the double tap daemon once Android is up (the driver itself is loaded in post-fs-data.sh).
MODDIR=${0%/*}
LOG=$MODDIR/dt2w.log
until [ "$(getprop sys.boot_completed)" = 1 ]; do sleep 2; done
for i in $(seq 1 30); do grep -qE "driver loaded|Staying|restoring|Disabling" $LOG 2>/dev/null && break; sleep 2; done
ls /sys/bus/i2c/devices/*/fts_gesture_mode >/dev/null 2>&1 || { echo "gesture driver not active, daemon not started" >> $LOG; exit 0; }
echo "android up, starting the double tap daemon" >> $LOG
while true; do
  sh $MODDIR/dt2w-daemon.sh >> $LOG 2>&1
  sleep 5
done
