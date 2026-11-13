#!/bin/bash
# xcodebuild for the Ritli scheme with CI's derived-data location. Callers add
# the configuration, destination, action and any test filters.
set -euo pipefail
exec xcodebuild \
  -project Ritli.xcodeproj \
  -scheme Ritli \
  -derivedDataPath "${RITLI_DERIVED_DATA:-$RUNNER_TEMP/DerivedData}" \
  "$@"
