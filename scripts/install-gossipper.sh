#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG="${ROOT}/upsipp.yml"
BIN_DIR="${ROOT}/bin"
mkdir -p "$BIN_DIR"

source "${ROOT}/scripts/bootstrap.sh"

VERSION="$(yq -r '.gossipper.version // "0.1.64"' "$CONFIG")"
ARCH="$(uname -m)"
OS="$(uname -s | tr '[:upper:]' '[:lower:]')"

case "$ARCH" in
  x86_64) ARCH="amd64" ;;
  aarch64|arm64) ARCH="arm64" ;;
  *) echo "Unsupported architecture: $ARCH" >&2; exit 1 ;;
esac

case "$OS" in
  linux) ASSET="gossipper_linux_${ARCH}" ;;
  darwin) ASSET="gossipper_darwin_${ARCH}" ;;
  *) echo "Unsupported OS: $OS" >&2; exit 1 ;;
esac

URL="https://github.com/sipcapture/gossipper/releases/download/v${VERSION}/${ASSET}"

echo "Installing gossipper ${VERSION} (${ASSET})..."
if ! curl -fsSL "$URL" -o "${BIN_DIR}/gossipper"; then
  URL="https://github.com/sipcapture/gossipper/releases/download/${VERSION}/${ASSET}"
  curl -fsSL "$URL" -o "${BIN_DIR}/gossipper"
fi
chmod +x "${BIN_DIR}/gossipper"
export PATH="${BIN_DIR}:${PATH}"
"${BIN_DIR}/gossipper" -version || true
echo "gossipper installed to ${BIN_DIR}/gossipper"
