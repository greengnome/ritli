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
