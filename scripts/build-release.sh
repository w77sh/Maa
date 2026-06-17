#!/usr/bin/env bash

set -euo pipefail

configuration="${1:-Release}"
marketing_version_override="${MARKETING_VERSION_OVERRIDE:-}"
build_number_override="${BUILD_NUMBER_OVERRIDE:-}"

if [[ "${configuration}" != "Release" && "${configuration}" != "Debug" ]]; then
  echo "Usage: $0 [Release|Debug]" >&2
  exit 1
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
project_dir="$(cd "${script_dir}/.." && pwd)"

project_path="${project_dir}/Drink Reminder.xcodeproj"
scheme="Drink Reminder"
derived_data_path="${project_dir}/.build/release"
app_name="Maa'.app"
app_path="${derived_data_path}/Build/Products/${configuration}/${app_name}"
dist_dir="${project_dir}/dist"

echo "Building ${scheme} (${configuration})..." >&2
build_args=(
  -project "${project_path}"
  -scheme "${scheme}"
  -configuration "${configuration}"
  -derivedDataPath "${derived_data_path}"
)

# Allow CI to inject deterministic release versions without mutating project files.
if [[ -n "${marketing_version_override}" ]]; then
  build_args+=(MARKETING_VERSION="${marketing_version_override}")
fi
if [[ -n "${build_number_override}" ]]; then
  build_args+=(CURRENT_PROJECT_VERSION="${build_number_override}")
fi

xcodebuild \
  "${build_args[@]}" \
  clean build >&2

if [[ ! -d "${app_path}" ]]; then
  echo "Build finished, but app was not found at:" >&2
  echo "  ${app_path}" >&2
  exit 1
fi

version="$(defaults read "${app_path}/Contents/Info" CFBundleShortVersionString)"
build_number="$(defaults read "${app_path}/Contents/Info" CFBundleVersion)"
artifact_name_zip="Maa-${version}-${build_number}-macOS.zip"
artifact_name_dmg="Maa-${version}-${build_number}-macOS.dmg"
artifact_path_zip="${dist_dir}/${artifact_name_zip}"
artifact_path_dmg="${dist_dir}/${artifact_name_dmg}"

mkdir -p "${dist_dir}"
rm -f "${artifact_path_zip}" "${artifact_path_dmg}"

if [[ -f "${project_dir}/release-notes.html" ]]; then
  echo "Copying release notes..." >&2
  cp "${project_dir}/release-notes.html" "${dist_dir}/Maa-${version}-${build_number}-macOS.html"
fi

echo "Packaging ${artifact_name_zip}..." >&2
ditto -c -k --sequesterRsrc --keepParent "${app_path}" "${artifact_path_zip}"

echo "Packaging ${artifact_name_dmg}..." >&2
if command -v create-dmg >/dev/null 2>&1; then
  create-dmg \
    --volname "Maa" \
    --background "${project_dir}/scripts/dmg-background.png" \
    --window-pos 200 120 \
    --window-size 600 400 \
    --icon-size 100 \
    --icon "Maa'.app" 150 190 \
    --hide-extension "Maa'.app" \
    --app-drop-link 450 190 \
    "${artifact_path_dmg}" \
    "${app_path}" >&2
else
  dmg_dir="${dist_dir}/dmg_tmp"
  mkdir -p "${dmg_dir}"
  cp -R "${app_path}" "${dmg_dir}/"
  ln -s /Applications "${dmg_dir}/Applications"

  hdiutil create -volname "Maa" -srcfolder "${dmg_dir}" -ov -format UDZO "${artifact_path_dmg}" >&2
  rm -rf "${dmg_dir}"
fi

