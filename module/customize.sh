# Install-time checks for the Odin 2 Portal double tap to wake module.
SUPPORTED_KERNELS="5.15.123-android13-8-g94ea6c79c823"

model="$(getprop ro.product.model)"
case "$model" in
  *"Odin2 Portal"*|*"Odin 2 Portal"*) ;;
  *) abort "! This module is only for the AYN Odin 2 Portal (found: $model)" ;;
esac

kernel="$(uname -r)"
case " $SUPPORTED_KERNELS " in
  *" $kernel "*) ui_print "- Kernel $kernel is supported" ;;
  *) ui_print "! Kernel $kernel hasn't been tested."
     ui_print "! The module will install but stay inactive (stock touch keeps working)." ;;
esac

set_perm $MODPATH/service.sh 0 0 0755
set_perm $MODPATH/dt2w-daemon.sh 0 0 0755
set_perm $MODPATH/fts_odin_dt2w.ko 0 0 0644
ui_print "- Reboot, then double tap the screen while it's off to wake it."
