#!/bin/sh
# Builds dist/odin2-portal-dt2w.zip from module/.
set -e
cd "$(dirname "$0")"
mkdir -p dist
rm -f dist/odin2-portal-dt2w.zip
(cd module && zip -qr -X ../dist/odin2-portal-dt2w.zip . -x '.*')
echo "built dist/odin2-portal-dt2w.zip"
