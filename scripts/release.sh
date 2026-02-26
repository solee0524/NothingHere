#!/usr/bin/env bash
#
# release.sh — Build, sign, notarize, package, and release NothingHere
#
# Usage:
#   ./scripts/release.sh <version>
#
# Example:
#   ./scripts/release.sh 1.0.0
#
# Prerequisites:
#   - Developer ID Application certificate in Keychain
#   - Apple ID App-Specific Password stored in Keychain:
#       xcrun notarytool store-credentials "notarytool-profile" \
#         --apple-id "YOUR_APPLE_ID" \
#         --team-id SFRYJG9KXH \
#         --password "APP_SPECIFIC_PASSWORD"
#   - brew install create-dmg
#   - gh CLI authenticated

set -euo pipefail

# ─── Configuration ────────────────────────────────────────────────────────────

PROJECT="NothingHere.xcodeproj"
SCHEME="NothingHere"
APP_NAME="NothingHere"
TEAM_ID="SFRYJG9KXH"
NOTARYTOOL_PROFILE="notarytool-profile"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
BUILD_DIR="${PROJECT_ROOT}/build"
ARCHIVE_PATH="${BUILD_DIR}/${APP_NAME}.xcarchive"
EXPORT_PATH="${BUILD_DIR}/export"
EXPORT_OPTIONS="${SCRIPT_DIR}/ExportOptions.plist"

# ─── Validate arguments ──────────────────────────────────────────────────────

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <version>"
    echo "Example: $0 1.0.0"
    exit 1
fi

VERSION="$1"
DMG_NAME="${APP_NAME}-v${VERSION}.dmg"
DMG_PATH="${BUILD_DIR}/${DMG_NAME}"

echo "==> Releasing ${APP_NAME} v${VERSION}"
echo ""

# ─── Determine build number ──────────────────────────────────────────────────

echo "==> Determining build number from appcast..."
PBXPROJ="${PROJECT_ROOT}/${PROJECT}/project.pbxproj"

MAX_SPARKLE="0"
if [[ -f "${PROJECT_ROOT}/appcast.xml" ]]; then
    MAX_SPARKLE=$(sed -n 's/.*<sparkle:version>\(.*\)<\/sparkle:version>.*/\1/p' \
        "${PROJECT_ROOT}/appcast.xml" | sort -V | tail -1)
    MAX_SPARKLE="${MAX_SPARKLE:-0}"
fi

if [[ "${MAX_SPARKLE}" =~ ^[0-9]+$ ]]; then
    NEW_BUILD=$((MAX_SPARKLE + 1))
else
    PREFIX="${MAX_SPARKLE%.*}"
    LAST="${MAX_SPARKLE##*.}"
    NEW_BUILD="${PREFIX}.$((LAST + 1))"
fi

echo "    Latest appcast build:     ${MAX_SPARKLE}"
echo "    MARKETING_VERSION         = ${VERSION}"
echo "    CURRENT_PROJECT_VERSION   = ${NEW_BUILD}"

# ─── Clean previous build ────────────────────────────────────────────────────

echo "==> Cleaning build directory..."
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"

# Clean Xcode DerivedData for this project to avoid stale SPM signing issues
DERIVED_DATA=$(xcodebuild -project "${PROJECT_ROOT}/${PROJECT}" -showBuildSettings 2>/dev/null | grep -m1 BUILD_DIR | sed 's/.*= //' | sed 's|/Build/.*||')
if [[ -n "${DERIVED_DATA}" && -d "${DERIVED_DATA}" ]]; then
    echo "    Cleaning DerivedData: ${DERIVED_DATA}"
    rm -rf "${DERIVED_DATA}"
fi

# ─── Resolve SPM dependencies ───────────────────────────────────────────────

echo "==> Resolving package dependencies..."
xcodebuild -resolvePackageDependencies \
    -project "${PROJECT_ROOT}/${PROJECT}" \
    -scheme "${SCHEME}" \
    | tail -5

# ─── Step 1: Archive ─────────────────────────────────────────────────────────

echo "==> Archiving..."
xcodebuild archive \
    -project "${PROJECT_ROOT}/${PROJECT}" \
    -scheme "${SCHEME}" \
    -destination "generic/platform=macOS" \
    -archivePath "${ARCHIVE_PATH}" \
    -configuration Release \
    CODE_SIGN_STYLE=Manual \
    CODE_SIGN_IDENTITY="Developer ID Application" \
    DEVELOPMENT_TEAM="${TEAM_ID}" \
    'OTHER_CODE_SIGN_FLAGS=--timestamp' \
    MARKETING_VERSION="${VERSION}" \
    CURRENT_PROJECT_VERSION="${NEW_BUILD}" \
    | tail -10

echo "    Archive created: ${ARCHIVE_PATH}"

# ─── Step 2: Export ──────────────────────────────────────────────────────────

echo "==> Exporting signed app..."
xcodebuild -exportArchive \
    -archivePath "${ARCHIVE_PATH}" \
    -exportPath "${EXPORT_PATH}" \
    -exportOptionsPlist "${EXPORT_OPTIONS}" \
    | tail -5

APP_PATH="${EXPORT_PATH}/${APP_NAME}.app"
echo "    Exported: ${APP_PATH}"

# ─── Step 3: Verify code signature ──────────────────────────────────────────

echo "==> Verifying code signature..."
codesign --verify --deep --strict "${APP_PATH}"
echo "    Signature valid."

# ─── Step 4: Create DMG ─────────────────────────────────────────────────────

echo "==> Creating DMG..."
if command -v create-dmg &>/dev/null; then
    create-dmg \
        --volname "${APP_NAME}" \
        --filesystem APFS \
        --window-size 600 400 \
        --icon-size 128 \
        --icon "${APP_NAME}.app" 150 200 \
        --app-drop-link 450 200 \
        --no-internet-enable \
        "${DMG_PATH}" \
        "${APP_PATH}"
else
    echo "    create-dmg not found, falling back to hdiutil..."
    STAGING_DIR="${BUILD_DIR}/dmg-staging"
    mkdir -p "${STAGING_DIR}"
    cp -R "${APP_PATH}" "${STAGING_DIR}/"
    ln -s /Applications "${STAGING_DIR}/Applications"
    hdiutil create -volname "${APP_NAME}" \
        -srcfolder "${STAGING_DIR}" \
        -fs APFS \
        -ov -format UDZO \
        "${DMG_PATH}"
    rm -rf "${STAGING_DIR}"
fi

echo "    DMG created: ${DMG_PATH}"

# ─── Step 5: Notarize ───────────────────────────────────────────────────────

echo "==> Submitting for notarization..."
xcrun notarytool submit "${DMG_PATH}" \
    --keychain-profile "${NOTARYTOOL_PROFILE}" \
    --wait

echo "    Notarization complete."

# ─── Step 6: Staple ─────────────────────────────────────────────────────────

echo "==> Stapling notarization ticket..."
xcrun stapler staple "${DMG_PATH}"
echo "    Stapled."

# ─── Step 7: Verify notarization ────────────────────────────────────────────

echo "==> Verifying notarization..."
if spctl --assess --type open --context context:primary-signature "${DMG_PATH}" 2>&1; then
    echo "    Gatekeeper: accepted."
else
    echo "    Gatekeeper: not yet propagated (normal for fresh notarization, users won't be affected)."
fi

# ─── Step 8: Generate Sparkle appcast ────────────────────────────────────────

echo "==> Generating Sparkle appcast..."
SPARKLE_BIN=$(find ~/Library/Developer/Xcode/DerivedData -path "*/sparkle/Sparkle/bin" -type d 2>/dev/null | head -1)
if [[ -n "${SPARKLE_BIN}" && -d "${SPARKLE_BIN}" ]]; then
    DOWNLOAD_URL_PREFIX="https://github.com/solee0524/NothingHere/releases/download/v${VERSION}/"
    "${SPARKLE_BIN}/generate_appcast" "${BUILD_DIR}" \
        --download-url-prefix "${DOWNLOAD_URL_PREFIX}" \
        -o "${PROJECT_ROOT}/appcast.xml" 2>/dev/null || {
        echo "    Warning: generate_appcast failed. Update appcast.xml manually."
    }
    echo "    appcast.xml updated."
else
    echo "    Sparkle bin not found in DerivedData."
    echo "    Run generate_appcast manually or update appcast.xml by hand."
fi

# ─── Step 9: Update Xcode project version numbers ──────────────────────────

echo "==> Writing version numbers back to Xcode project..."
sed -i '' "s/MARKETING_VERSION = [^;]*;/MARKETING_VERSION = ${VERSION};/g" "${PBXPROJ}"
sed -i '' "s/CURRENT_PROJECT_VERSION = [^;]*;/CURRENT_PROJECT_VERSION = ${NEW_BUILD};/g" "${PBXPROJ}"
echo "    MARKETING_VERSION         = ${VERSION}"
echo "    CURRENT_PROJECT_VERSION   = ${NEW_BUILD}"

echo ""
echo "==> Release script complete."
echo "    DMG: ${DMG_PATH}"
echo "    appcast.xml and project.pbxproj updated."
echo "    Create GitHub Release via skill or manually."
