# Install-time checks. Verified on the Odin 2 Portal; other Odin 2 family devices are experimental.
mfr="$(getprop ro.product.manufacturer)"
plat="$(getprop ro.board.platform)"
model="$(getprop ro.product.model)"

[ "$mfr" = "AYN" ] && [ "$plat" = "kalama" ] || \
  abort "! This module is for AYN Odin 2 family devices (Snapdragon 8 Gen 2). Found: $mfr $model ($plat)"

case "$model" in
  *Portal*) ui_print "- $model: verified" ;;
  *) ui_print "! $model hasn't been tested yet."
     ui_print "! It will try on boot and fall back to the stock touch driver if anything doesn't fit."
     ui_print "! Please report how it went (see the GitHub page)." ;;
esac

if ! ls -d /sys/bus/i2c/drivers/fts_ts/*-* >/dev/null 2>&1; then
  ui_print "! No FocalTech touchscreen found, so this module will stay inactive on this device."
fi

set_perm $MODPATH/post-fs-data.sh 0 0 0755
set_perm $MODPATH/service.sh 0 0 0755
set_perm $MODPATH/dt2w-daemon.sh 0 0 0755
set_perm $MODPATH/compat-check.sh 0 0 0755
set_perm $MODPATH/fts_odin_dt2w.ko 0 0 0644
ui_print "- Reboot, then double tap the screen while it's off to wake it."
ui_print "- Log: /data/adb/modules/odin2portal_dt2w/dt2w.log"
