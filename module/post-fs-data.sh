#!/system/bin/sh
# Early boot (post-fs-data): swap in the gesture-capable FocalTech driver before the UI starts,
# so it already knows the screen state. service.sh starts the double tap daemon later.
# The swap runs in the background: the stock driver can only be unloaded once its firmware lookup
# finishes, and that lookup waits for this boot stage to end.
# Verified on the Odin 2 Portal. On anything else it tries, and puts the stock driver back if
# anything doesn't fit. If a load attempt ever doesn't finish (crash), it disables itself.
MODDIR=${0%/*}
LOG=$MODDIR/dt2w.log
KO=$MODDIR/fts_odin_dt2w.ko
RUN=$MODDIR/run.ko
VERIFIED_KERNELS="5.15.123-android13-8-g94ea6c79c823"
VM_OFF=221669   # offset of "vermagic=" in fts_odin_dt2w.ko
VM_CAP=81       # bytes available for "vermagic=<string>" + NUL padding

log() { echo "[$(cut -d" " -f1 /proc/uptime)] $*" >> $LOG; }
# Magisk/KernelSU run this in busybox's standalone shell, whose modinfo/insmod/rmmod differ from Android's.
INSMOD=/system/bin/insmod; RMMOD=/system/bin/rmmod; MODINFO=/system/bin/modinfo
vermagic_of() {
  v=$($MODINFO -F vermagic "$1" 2>/dev/null)
  [ -n "$v" ] || v=$(grep -ao 'vermagic=[ -~]*' "$1" | head -1 | cut -d= -f2-)
  echo "$v"
}

main() {
  echo "[$(cut -d" " -f1 /proc/uptime)] boot $(date) | $(getprop ro.product.model) | $(getprop ro.build.display.id) | $(uname -r)" > $LOG

  if [ -f $MODDIR/.loading ]; then
    log "the last driver load never finished (crash, or a reboot mid-load). Disabling the module; stock touch stays."
    rm -f $MODDIR/.loading; touch $MODDIR/disable; return 0
  fi

  case "$(uname -r)" in
    5.15.*) ;;
    *) log "kernel $(uname -r) isn't 5.15, this driver can't load here. Staying stock."; return 0 ;;
  esac

  TPNAME=""
  for d in /sys/bus/i2c/drivers/fts_ts/*-*; do [ -e "$d" ] && { TPNAME=${d##*/}; break; }; done
  [ -n "$TPNAME" ] || { log "no FocalTech (fts_ts) touchscreen on this device. Staying stock."; return 0; }
  TP=/sys/bus/i2c/devices/$TPNAME

  STOCK=""
  for p in /vendor_dlkm/lib/modules /vendor/lib/modules /system_dlkm/lib/modules; do
    [ -f $p/focaltech_fts.ko ] && { STOCK=$p/focaltech_fts.ko; break; }
  done
  [ -n "$STOCK" ] || { log "stock focaltech_fts.ko not found (built into the kernel?). Staying stock."; return 0; }

  has_touch() { grep -qx fts_ts /sys/class/input/input*/name 2>/dev/null; }
  restore_stock() {
    log "$1, restoring the stock driver"
    $RMMOD focaltech_fts >> $LOG 2>&1
    $INSMOD $STOCK >> $LOG 2>&1
    rm -f $MODDIR/.loading
    exit 0   # main runs in its own background shell, so this only ends the swap
  }

  if [ -e $TP/fts_gesture_mode ]; then
    log "gesture driver already loaded"
  else
    # Stamp the driver with this kernel's own vermagic so the kernel's symbol version check decides.
    VM=$(vermagic_of $STOCK)
    [ -n "$VM" ] && [ ${#VM} -le $((VM_CAP - 10)) ] || { log "can't read a usable vermagic from $STOCK. Staying stock."; return 0; }
    cp -f $KO $RUN
    printf 'vermagic=%s' "$VM" | dd of=$RUN bs=1 seek=$VM_OFF conv=notrunc 2>/dev/null
    dd if=/dev/zero of=$RUN bs=1 seek=$((VM_OFF + 9 + ${#VM})) count=$((VM_CAP - 9 - ${#VM})) conv=notrunc 2>/dev/null
    [ "$(vermagic_of $RUN)" = "$VM" ] || { log "vermagic stamp failed. Staying stock."; return 0; }

    case " $VERIFIED_KERNELS " in
      *" $(uname -r) "*) log "verified kernel" ;;
      *) log "untested kernel, trying (experimental)" ;;
    esac

    touch $MODDIR/.loading; sync
    $RMMOD focaltech_fts >> $LOG 2>&1
    sleep 1
    $INSMOD $RUN >> $LOG 2>&1 || restore_stock "the kernel refused the driver"
    for i in 1 2 3 4 5 6 7 8 9 10; do has_touch && break; sleep 0.5; done
    has_touch || restore_stock "touchscreen didn't come back"
    [ -e $TP/fts_gesture_mode ] || restore_stock "gesture support didn't appear"
    rm -f $MODDIR/.loading
  fi

  log "driver loaded on $TPNAME, $(head -1 $TP/fts_gesture_mode), $(grep -o 'IC ID:.*' $TP/fts_driver_info)"
}

main </dev/null >/dev/null 2>&1 &
