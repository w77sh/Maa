#!/usr/bin/env bash

set -euo pipefail

configuration="${1:-Release}"

if [[ "${configuration}" != "Debug" && "${configuration}" != "Release" ]]; then
  echo "Usage: $0 [Debug|Release]" >&2
  exit 1
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
project_dir="$(cd "${script_dir}/.." && pwd)"

project_path="${project_dir}/Drink Reminder.xcodeproj"
scheme="Drink Reminder"
derived_data_path="${project_dir}/.build"
app_name="Maa'.app"
built_app_path="${derived_data_path}/Build/Products/${configuration}/${app_name}"
install_dir="${HOME}/Applications"
install_app_path="${install_dir}/${app_name}"

echo "Building ${scheme} (${configuration})..."
xcodebuild \
  -project "${project_path}" \
  -scheme "${scheme}" \
  -configuration "${configuration}" \
  -derivedDataPath "${derived_data_path}" \
  build

if [[ ! -d "${built_app_path}" ]]; then
  echo "Build finished, but app was not found at:" >&2
  echo "  ${built_app_path}" >&2
  exit 1
fi

mkdir -p "${install_dir}"

if pgrep -f "Maa'.app" >/dev/null 2>&1 || pgrep -x "Maa'" >/dev/null 2>&1; then
  echo "Stopping running app..."
  pkill -f "Maa'.app" || pkill -x "Maa'" || true
  sleep 1
fi

echo "Installing to ${install_app_path}..."
rm -rf "${install_app_path}"
ditto "${built_app_path}" "${install_app_path}"

echo "Launching app..."
open "${install_app_path}"

echo "Done."
echo "Installed app: ${install_app_path}"
