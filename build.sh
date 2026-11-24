#!/usr/bin/env bash
# Builds the bridge and the app, and installs the app on $DEVICE.
set -euo pipefail
cd "$(dirname "$0")"

DEVICE=${DEVICE:-8214eb05}
# DEVICE=192.168.1.110:42899 && adb connect $DEVICE

tool/build_bridge.sh --asset

cd droidshock3
flutter clean && flutter build apk --release --target-platform=android-arm64
adb -s "$DEVICE" install build/app/outputs/flutter-apk/app-release.apk
