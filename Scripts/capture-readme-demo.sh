#!/usr/bin/env bash

set -euo pipefail

usage="Usage: capture-readme-demo.sh <simulator-udid> <output-gif>"

if [[ ${1:-} == "--help" ]]; then
  echo "$usage"
  exit 0
fi

if [[ $# -ne 2 ]]; then
  echo "$usage" >&2
  exit 64
fi

simulator_udid=$1
output_gif=$2
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd "$script_dir/.." && pwd)
cd "$repo_root"

if ! xcrun simctl list devices available | grep -Fq "$simulator_udid"; then
  echo "Simulator is not available: $simulator_udid" >&2
  exit 65
fi

capture_dir=$(mktemp -d /private/tmp/viewmonitor-readme-demo.XXXXXX)
derived_data="$capture_dir/DerivedData"
mp4_path="$capture_dir/viewmonitor-swiftui-demo.mp4"
record_log="$capture_dir/record-video.log"
build_log="$capture_dir/build-for-testing.log"
test_log="$capture_dir/test.log"
converter_bin="$capture_dir/video-to-gif"
module_cache="$capture_dir/ModuleCache"
recorder_pid=""

stop_recording() {
  if [[ -n "$recorder_pid" ]] && kill -0 "$recorder_pid" 2>/dev/null; then
    kill -INT "$recorder_pid"
    wait "$recorder_pid" || true
  fi
  recorder_pid=""
}

trap stop_recording EXIT INT TERM

mkdir -p "$module_cache"
CLANG_MODULE_CACHE_PATH="$module_cache" xcrun swiftc \
  -parse-as-library \
  "$script_dir/video-to-gif.swift" \
  -o "$converter_bin"

if ! xcrun simctl list devices | grep -F "$simulator_udid" | grep -Fq '(Booted)'; then
  xcrun simctl boot "$simulator_udid"
fi
xcrun simctl bootstatus "$simulator_udid" -b

xcodebuild build-for-testing \
  -project Example/ViewMonitorSwiftUIExample/ViewMonitorSwiftUIExample.xcodeproj \
  -scheme ViewMonitorSwiftUIExample \
  -destination "platform=iOS Simulator,id=$simulator_udid" \
  -derivedDataPath "$derived_data" \
  OTHER_SWIFT_FLAGS=-DVIEWMONITOR_CAPTURE_DEMO \
  | tee "$build_log"

xcrun simctl io "$simulator_udid" recordVideo \
  --codec=h264 \
  --force \
  "$mp4_path" \
  >"$record_log" 2>&1 &
recorder_pid=$!

recording_started=false
for _ in {1..100}; do
  if grep -Fq 'Recording started' "$record_log"; then
    recording_started=true
    break
  fi
  if ! kill -0 "$recorder_pid" 2>/dev/null; then
    echo "Simulator recording stopped before the first frame." >&2
    exit 66
  fi
  sleep 0.1
done

if [[ "$recording_started" != true ]]; then
  echo "Timed out waiting for Simulator recording to start." >&2
  exit 67
fi

xcodebuild test-without-building \
  -project Example/ViewMonitorSwiftUIExample/ViewMonitorSwiftUIExample.xcodeproj \
  -scheme ViewMonitorSwiftUIExample \
  -destination "platform=iOS Simulator,id=$simulator_udid" \
  -derivedDataPath "$derived_data" \
  -only-testing:ViewMonitorSwiftUIExampleUITests/ViewMonitorUITests/testReadmeDemoCapture \
  OTHER_SWIFT_FLAGS=-DVIEWMONITOR_CAPTURE_DEMO \
  | tee "$test_log"

stop_recording
trap - EXIT INT TERM

"$converter_bin" \
  "$mp4_path" \
  "$output_gif" \
  --width 360 \
  --fps 10 \
  --max-bytes 10485760

echo "MP4 master: $mp4_path"
echo "GIF: $output_gif"
