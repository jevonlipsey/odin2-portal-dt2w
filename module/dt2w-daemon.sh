#!/system/bin/sh
# Wakes the screen on two separate taps within 0.5 s while it's off.
# The driver reports every touch during screen-off as KEY_F24; this script does the timing.

for b in /data/adb/magisk/busybox /data/adb/ksu/bin/busybox /data/adb/ap/bin/busybox; do
  [ -x "$b" ] && { BB="$b"; break; }
done
DD="${BB:+$BB }dd"
OD="${BB:+$BB }od"

find_dev() {
  for e in /sys/class/input/event*; do
    [ "$(cat $e/device/name 2>/dev/null)" = fts_ts ] && { echo /dev/input/${e##*/}; return; }
  done
}

EV=$(find_dev)
[ -c "$EV" ] || exit 1

F24=$((1 + 194 * 65536))   # EV_KEY | KEY_F24 << 16
TAP_GAP=60000              # us without touch events = finger lifted
DOUBLE_WINDOW=500000       # second tap must start within this of the first
MAX_TAP=300000             # first tap can't be longer than this (ignores long presses)
COOLDOWN=1500000

last=0; prevstart=0; prevend=0; cool=0
while true; do
  set -- $($DD if=$EV bs=24 count=1 2>/dev/null | $OD -An -tu4 -v)
  [ $# -ge 6 ] || { sleep 1; EV=$(find_dev); continue; }
  [ "$5" = "$F24" ] && [ "$6" = 1 ] || continue
  t=$(( $1 * 1000000 + $3 ))
  [ $t -lt $cool ] && continue
  if [ $((t - last)) -gt $TAP_GAP ]; then
    if [ $prevstart -gt 0 ] && [ $((t - prevstart)) -lt $DOUBLE_WINDOW ] && [ $((prevend - prevstart)) -lt $MAX_TAP ]; then
      input keyevent 224
      cool=$((t + COOLDOWN)); prevstart=0; last=$t
      continue
    fi
    prevstart=$t
  fi
  prevend=$t; last=$t
done
