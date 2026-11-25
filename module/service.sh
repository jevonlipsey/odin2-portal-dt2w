#!/system/bin/sh
# Swap in the gesture-capable touch driver after boot, then run the double tap daemon.
# Anything unexpected -> put the stock driver back and stop.
MODDIR=${0%/*}
LOG=$MODDIR/dt2w.log
TP=/sys/bus/i2c/devices/4-0038
STOCK=/vendor/lib/modules/focaltech_fts.ko
SUPPORTED_KERNELS="5.15.123-android13-8-g94ea6c79c823"

until [ "$(getprop sys.boot_completed)" = 1 ]; do sleep 2; done
sleep 5
echo "boot $(date)" > $LOG

case " $SUPPORTED_KERNELS " in
  *" $(uname -r) "*) ;;
  *) echo "kernel $(uname -r) not supported, staying on the stock driver" >> $LOG; exit 0 ;;
esac

has_touch() { getevent -pl 2>/dev/null | grep -q '"fts_ts"'; }
restore_stock() {
  echo "$1, restoring the stock driver" >> $LOG
  rmmod focaltech_fts >> $LOG 2>&1
  insmod $STOCK >> $LOG 2>&1
  exit 0
}

if [ ! -e $TP/fts_gesture_mode ]; then
  rmmod focaltech_fts >> $LOG 2>&1
  sleep 1
  insmod $MODDIR/fts_odin_dt2w.ko >> $LOG 2>&1 || restore_stock "driver failed to load"
  sleep 4
  { has_touch && [ -e $TP/fts_gesture_mode ]; } || restore_stock "touchscreen missing after load"
fi

echo "driver loaded, $(head -1 $TP/fts_gesture_mode)" >> $LOG
sleep 2
while true; do
  sh $MODDIR/dt2w-daemon.sh >> $LOG 2>&1
  sleep 5
done
