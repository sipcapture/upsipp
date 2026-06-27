#!/usr/bin/env bash
# Install runtime dependencies (yq) when missing. Safe to call repeatedly.
set -euo pipefail

install_yq() {
  if command -v yq >/dev/null 2>&1; then
    return 0
  fi

  local root
  root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  local bindir="${UPSIPP_BIN_DIR:-${root}/bin}"
  mkdir -p "$bindir"

  if [[ -x "${bindir}/yq" ]]; then
    export PATH="${bindir}:${PATH}"
    return 0
  fi

  local arch os bin
  os="$(uname -s | tr '[:upper:]' '[:lower:]')"
  arch="$(uname -m)"
  case "$arch" in
    x86_64) arch="amd64" ;;
    aarch64|arm64) arch="arm64" ;;
    *) echo "Unsupported architecture: $arch" >&2; exit 1 ;;
  esac
  case "$os" in
    linux) bin="yq_linux_${arch}" ;;
    darwin) bin="yq_darwin_${arch}" ;;
    *) echo "Unsupported OS: $os" >&2; exit 1 ;;
  esac

  curl -fsSL "https://github.com/mikefarah/yq/releases/download/v4.44.3/${bin}" -o "${bindir}/yq"
  chmod +x "${bindir}/yq"
  export PATH="${bindir}:${PATH}"
}

install_yq
