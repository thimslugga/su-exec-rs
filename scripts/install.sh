#!/bin/bash
#set -euo pipefail

GIT_REPO="thimslugga/su-exec-rs"
BIN_NAME="su-exec-rs"
BIN_DIR="/usr/local/bin"
TMP_DIR="/tmp"

# Function to determine the platform
function detectPlatform() {
  local os platform
  os="$(uname -s)"

  case "${os}" in
  Linux)
    platform="linux"
    ;;
  Darwin)
    # macOS
    platform="darwin"
    ;;
  FreeBSD)
    platform="freebsd"
    ;;
  CYGWIN* | MINGW* | MSYS*)
    platform="windows"
    ;;
  *)
    echo "Unsupported platform: ${os:-unknonwn}"
    exit 1
    ;;
  esac

  local arch architecture
  _arch="$(uname -m)"

  case "${arch}" in
  x86_64 | amd64)
    architecture="amd64"
    ;;
  i386 | i686)
    architecture="386"
    ;;
  armv7l | armv6l)
    architecture="armv7"
    ;;
  aarch64 | arm64)
    architecture="arm64"
    ;;
  *)
    echo "Unsupported architecture: ${arch:-unknown}"
    exit 1
    ;;
  esac

  echo "${platform}_${architecture}"
}

# Function to determine the preferred archive format
function setArchiveFormat() {
  local pfa
  pfa="$1"

  if [[ "${pfa}" == windows-* ]]; then
    echo "zip"
  else
    if command -v tar >/dev/null 2>&1; then
      echo "tar.gz"
    elif command -v unzip >/dev/null 2>&1; then
      echo "zip"
    else
      echo "Unsupported: neither tar + gzip or unzip are available."
      exit 1
    fi
  fi
}

main() {
  local pfa
  # Determine the platform and architecture
  pfa=$(detectPlatform)

  # Determine preferred archive format
  file_ext=$(selectArchiveFormat "${pfa}")

  # Get the latest release download URL from GitHub API
  latest_release_url="$(curl -sSfL "https://api.github.com/repos/${GIT_REPO}/releases/latest" | grep "browser_download_url" | grep "$pfa.$file_ext" | cut -d '"' -f 4 | head -n 1)"

  if [[ -z "${latest_release_url}" ]]; then
    echo "No release found for platform $pfa with format $file_ext"
    exit 1
  fi

  # Create tmp directory
  TMP_DIR="$(mktemp -d)"

  archive_path="$TMP_DIR/$BIN_NAME.$file_ext"

  # Download the release archive
  echo "Downloading $BIN_NAME from $latest_release_url..."
  curl -sfSL "$latest_release_url" -o "$archive_path"

  # Extract the archive
  echo "Extracting $BIN_NAME.. "
  if [ "$file_ext" == "zip" ]; then
    unzip -d "$TMP_DIR" "$archive_path"
  elif [ "$file_ext" == "tar.gz" ]; then
    tar -xzf "$archive_path" -C "$TMP_DIR"
  else
    echo "Unsupported file extension: $file_ext"
    exit 1
  fi

  # Find the binary, assuming it's in the extracted files and make executable
  bin_path=$(find "$TMP_DIR" -type f -name "$BIN_NAME")
  chmod +x "$bin_path"

  # Install the binary
  if [[ "${pfa}" = "windows-amd64" ]] || [[ "${pfa}" = "windows-386" ]]; then
    BIN_DIR="$HOME/bin"
    mkdir -p "$BIN_DIR"
    mv "$bin_path" "$BIN_DIR/$BIN_NAME.exe"
  else
    sudo su <<EOF
      [[ "$(uname -s)" == 'Linux' ]] && setcap cap_net_admin=eip "$bin_path"
      mv "${bin_path}" "$BIN_DIR/$BIN_NAME"
EOF
  fi

  # Clean up
  test -d "${TMP_DIR}" && rm -rf "${TMP_DIR}"

  echo "${BIN_NAME} installed successfully!"
}

# Run the installation
main
