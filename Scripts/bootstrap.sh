#!/usr/bin/env bash
# shellcheck source=/dev/null
# Usage: ./bootstrap.sh
# This script will:
#   - install SwiftLint, SwiftFormat, SwiftGen
#   - link git hooks
#   - install allure dependencies if `INSTALL_ALLURE` environment variable is provided
#   - install sonar-scanner if `INSTALL_SONAR` environment variable is provided
# If you get `zsh: permission denied: ./bootstrap.sh` error, please run `chmod +x bootstrap.sh` first

function puts {
  echo
  echo -e "👉 ${1}"
}

# Set bash to Strict Mode (http://redsymbol.net/articles/unofficial-bash-strict-mode/)
set -Eeuo pipefail

trap "echo ; echo ❌ The Bootstrap script failed to finish without error. See the log above to debug. ; echo" ERR

source ./Githubfile

reuse_version() {
  local version=$1 output pattern
  shift
  [[ ${IS_SELF_HOSTED:-false} == true ]] || return 1
  output=$("$@" 2>/dev/null) || return 1
  pattern=${version//./\\.}
  grep -Eq "(^|[^[:alnum:].+-])v?${pattern}([^[:alnum:].+-]|$)" <<< "$output" || return 1
  puts "Reuse $1 v$version"
}

# These tools do not expose a version command. Match their pinned binaries.
reuse_binary() {
  local name=$1 checksum=$2 binary
  [[ ${IS_SELF_HOSTED:-false} == true ]] || return 1
  binary=$(command -v "$name") || return 1
  [[ $(shasum -a 256 "$binary" | awk '{print $1}') == "$checksum" ]] || return 1
  puts "Reuse $name"
}

if [ "${GITHUB_ACTIONS:-}" != "true" ]; then
  puts "Set up git hooks"
  bundle install
  bundle exec lefthook install
fi

if [[ ${GITHUB_ACTIONS:-} == true ]] && ! command -v xcbeautify >/dev/null; then
  puts "Install xcbeautify for Xcode test output"
  CI=1 HOMEBREW_NO_AUTO_UPDATE=1 brew install xcbeautify
fi

if [ "${SKIP_SWIFT_BOOTSTRAP:-}" != true ]; then
  if ! reuse_version "$SWIFT_LINT_VERSION" swiftlint version; then
    puts "Install SwiftLint v${SWIFT_LINT_VERSION}"
    DOWNLOAD_URL="https://github.com/realm/SwiftLint/releases/download/${SWIFT_LINT_VERSION}/SwiftLint.pkg"
    DOWNLOAD_PATH="/tmp/SwiftLint-${SWIFT_LINT_VERSION}.pkg"
    wget "$DOWNLOAD_URL" -O "$DOWNLOAD_PATH"
    sudo installer -pkg "$DOWNLOAD_PATH" -target /
    swiftlint version
  fi

  if ! reuse_version "$SWIFT_FORMAT_VERSION" swiftformat --version; then
    puts "Install SwiftFormat v${SWIFT_FORMAT_VERSION}"
    DOWNLOAD_URL="https://github.com/nicklockwood/SwiftFormat/releases/download/${SWIFT_FORMAT_VERSION}/swiftformat.zip"
    DOWNLOAD_PATH="/tmp/swiftformat-${SWIFT_FORMAT_VERSION}.zip"
    BIN_PATH="/usr/local/bin/swiftformat"
    brew uninstall swiftformat || true
    wget "$DOWNLOAD_URL" -O "$DOWNLOAD_PATH"
    unzip -o "$DOWNLOAD_PATH" -d "/tmp/swiftformat-${SWIFT_FORMAT_VERSION}"
    sudo mv "/tmp/swiftformat-${SWIFT_FORMAT_VERSION}/swiftformat" "$BIN_PATH"
    sudo chmod +x "$BIN_PATH"
    swiftformat --version
  fi

  if ! reuse_version "$SWIFT_GEN_VERSION" swiftgen --version; then
    puts "Install SwiftGen v${SWIFT_GEN_VERSION}"
    DOWNLOAD_URL="https://github.com/SwiftGen/SwiftGen/releases/download/${SWIFT_GEN_VERSION}/swiftgen-${SWIFT_GEN_VERSION}.zip"
    DOWNLOAD_PATH="/tmp/swiftgen-${SWIFT_GEN_VERSION}.zip"
    INSTALL_DIR="/usr/local/lib/swiftgen"
    BIN_PATH="/usr/local/bin/swiftgen"
    wget "$DOWNLOAD_URL" -O "$DOWNLOAD_PATH"
    sudo rm -rf "$INSTALL_DIR"
    sudo install -d -m 755 /usr/local/lib "$INSTALL_DIR"
    sudo unzip -o "$DOWNLOAD_PATH" -d "$INSTALL_DIR"
    sudo chmod -R a+rX "$INSTALL_DIR"
    sudo rm -f "$BIN_PATH"
    sudo ln -s "$INSTALL_DIR/bin/swiftgen" "$BIN_PATH"
    swiftgen --version
  fi
fi

if [[ ${INSTALL_SONAR-default} == true ]]; then
  if reuse_version "$SONAR_VERSION" ./fastlane/sonar/bin/sonar-scanner --version; then
    :
  elif reuse_version "$SONAR_VERSION" sonar-scanner --version; then
    sonar_home=$(python3 -c 'import pathlib,sys; print(pathlib.Path(sys.argv[1]).resolve().parent.parent)' "$(command -v sonar-scanner)")
    rm -rf fastlane/sonar
    ln -sfn "$sonar_home" fastlane/sonar
  else
    puts "Install sonar scanner v${SONAR_VERSION}"
    DOWNLOAD_URL="https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-${SONAR_VERSION}-macosx-x64.zip"
    wget "${DOWNLOAD_URL}" -O ./fastlane/sonar.zip
    cd fastlane
    unzip sonar.zip
    rm sonar.zip
    cd ..
    rm -rf fastlane/sonar
    mv "fastlane/sonar-scanner-${SONAR_VERSION}-macosx-x64/" fastlane/sonar/
    chmod +x ./fastlane/sonar/bin/sonar-scanner
  fi
fi

if [[ ${INSTALL_ALLURE-default} == true ]]; then
  if reuse_version "$ALLURECTL_VERSION" allurectl --version; then
    ln -sf "$(command -v allurectl)" ./fastlane/allurectl
  else
    puts "Install allurectl v${ALLURECTL_VERSION}"
    DOWNLOAD_URL="https://github.com/allure-framework/allurectl/releases/download/${ALLURECTL_VERSION}/allurectl_darwin_amd64"
    wget "${DOWNLOAD_URL}" -O ./fastlane/allurectl
    chmod +x ./fastlane/allurectl
  fi

  if reuse_binary xcresults "$XCRESULTS_SHA256"; then
    ln -sf "$(command -v xcresults)" ./fastlane/xcresults
  else
    puts "Install xcresults v${XCRESULTS_VERSION}"
    DOWNLOAD_URL="https://github.com/eroshenkoam/xcresults/releases/download/${XCRESULTS_VERSION}/xcresults"
    wget "${DOWNLOAD_URL}" -O ./fastlane/xcresults
    chmod +x ./fastlane/xcresults
  fi
fi

if [[ ${INSTALL_VIDEO_BUDDY-default} == true ]]; then
  if ! reuse_version "$PLAYWRIGHT_VERSION" playwright --version; then
    puts "Install playwright v${PLAYWRIGHT_VERSION}"
    npm install -g "playwright@${PLAYWRIGHT_VERSION}"
  fi
  # Playwright skips downloads when the required browser is already installed.
  npx playwright install chromium

  if ! reuse_version "$STREAM_VIDEO_BUDDY_VERSION" npm list --global --depth=0 stream-video-buddy; then
    puts "Install stream-video-buddy v${STREAM_VIDEO_BUDDY_VERSION}"
    npm install -g "https://github.com/GetStream/stream-video-buddy#${STREAM_VIDEO_BUDDY_VERSION}"
  fi
fi

if [[ ${INSTALL_YEETD-default} == true ]]; then
  if ! command -v yeetd >/dev/null || ! reuse_version "$YEETD_VERSION" pkgutil --pkg-info dev.biscuit.yeetd; then
    PACKAGE="yeetd-normal.pkg"
    puts "Install yeetd v${YEETD_VERSION}"
    wget "https://github.com/biscuitehh/yeetd/releases/download/${YEETD_VERSION}/${PACKAGE}"
    sudo installer -pkg ${PACKAGE} -target /
  fi
  if ! pgrep -x yeetd >/dev/null; then
    puts "Running yeetd daemon"
    yeetd &
  fi
fi

if [[ ${INSTALL_IPSW-default} == true ]] && ! reuse_version "$IPSW_VERSION" ipsw version; then
  puts "Install ipsw v${IPSW_VERSION}"
  FILE="ipsw_${IPSW_VERSION}_macOS_universal.tar.gz"
  wget "https://github.com/blacktop/ipsw/releases/download/v${IPSW_VERSION}/${FILE}"
  tar -xzf "$FILE"
  chmod +x ipsw
  sudo mv ipsw /usr/local/bin/
fi

if [[ ${INSTALL_INTERFACE_ANALYZER-default} == true ]] && ! reuse_binary interface-analyser "$INTERFACE_ANALYZER_SHA256"; then
  puts "Install interface-analyser v${INTERFACE_ANALYZER_VERSION}"
  FILE="interface-analyser"
  wget "https://github.com/GetStream/stream-module-interface-analyser/releases/download/v${INTERFACE_ANALYZER_VERSION}/${FILE}"
  chmod +x ${FILE}
  sudo mv ${FILE} /usr/local/bin/
fi
