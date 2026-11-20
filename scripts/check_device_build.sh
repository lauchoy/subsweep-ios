#!/bin/sh
# Builds SubSweep for a real iPhone (unsigned) and fails if the Simulator-only Pro unlock made it into the binary.
set -eu
cd "$(dirname "$0")/.."
DERIVED=build/device-check
xcodebuild -project SubSweep.xcodeproj -scheme SubSweep -configuration Release \
  -destination 'generic/platform=iOS' -derivedDataPath "$DERIVED" \
  CODE_SIGNING_ALLOWED=NO build -quiet
BIN="$DERIVED/Build/Products/Release-iphoneos/SubSweep.app/SubSweep"
if strings "$BIN" | grep -q simulatorFallbackUnlock; then
  echo "FAIL: Simulator Pro unlock is present in the device build" >&2
  exit 1
fi
echo "OK: device build has no Simulator Pro unlock"
