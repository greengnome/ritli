#!/bin/bash
set -euo pipefail

: "${GITHUB_ENV:?GITHUB_ENV must point to the workflow environment file}"
runtime_version="${IOS_RUNTIME_VERSION:-26.5}"

available_runtime() {
  xcrun simctl list runtimes --json | jq -r --arg version "$runtime_version" '
    [.runtimes[] | select(
      (.identifier | startswith("com.apple.CoreSimulator.SimRuntime.iOS-"))
      and .version == $version
      and .isAvailable == true
    )][0].identifier // empty
  '
}

xcrun simctl list runtimes
runtime_id="$(available_runtime)"
if [[ -z "$runtime_id" ]]; then
  echo "Installing the missing iOS $runtime_version simulator runtime."
  xcodebuild -downloadPlatform iOS -buildVersion "$runtime_version"
  runtime_id="$(available_runtime)"
fi

if [[ -z "$runtime_id" ]]; then
  echo "::error::iOS $runtime_version is not available after runtime installation."
  xcrun simctl list runtimes
  exit 1
fi

# Hosted images do not always expose a pre-created iPhone destination.
simulator_id="$(xcrun simctl create "Ritli CI" \
  com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro "$runtime_id")"
echo "IOS_SIMULATOR_ID=$simulator_id" >> "$GITHUB_ENV"
echo "Using iPhone 17 Pro on iOS $runtime_version: $simulator_id"
xcrun simctl bootstatus "$simulator_id" -b

# A successful CoreSimulator boot does not guarantee that Xcode has discovered
# the device yet on a fresh hosted runner. Wait for an eligible destination.
wait_for_destination() {
  local attempt destinations
  for attempt in {1..6}; do
    if destinations="$(xcodebuild -project Ritli.xcodeproj -scheme Ritli \
      -showdestinations -destination-timeout 30 2>&1)"; then
      if awk -v simulator_id="$simulator_id" '
        /Available destinations for|Destinations compatible with/ { available = 1; next }
        /Ineligible destinations for|Destinations incompatible with/ { available = 0 }
        available && /platform:iOS Simulator,/ && index($0, "id:" simulator_id ",") {
          found = 1
        }
        END { exit !found }
      ' <<< "$destinations"; then
        echo "Xcode recognizes the test simulator: $simulator_id"
        return 0
      fi
    fi

    printf '%s\n' "$destinations"
    if [[ "$attempt" -lt 6 ]]; then
      echo "Waiting for Xcode to discover the test simulator (attempt $attempt/6)."
      sleep 10
    fi
  done
  return 1
}

if wait_for_destination; then
  exit 0
fi

# Repeating discovery alone can leave a hosted runner stuck with only generic
# destinations. Reconnect Xcode to CoreSimulator once before failing the job.
echo "::warning::Restarting CoreSimulator after Xcode failed to discover the booted device."
xcrun simctl shutdown "$simulator_id" || true
killall -u "$(id -un)" com.apple.CoreSimulator.CoreSimulatorService || true
xcrun simctl bootstatus "$simulator_id" -b
if wait_for_destination; then
  exit 0
fi

echo "::error::Xcode did not expose the booted simulator as an eligible test destination after recovery."
xcrun simctl list runtimes
xcrun simctl list devices available
exit 1
