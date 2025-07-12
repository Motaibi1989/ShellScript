#!/bin/bash

# --------------------------------------------
# OpenSSL 3.0.13 Installer 
# Author: Mohammed Alotaibi (motaibi1989.com)
# Last Update: 2025-07-12
# --------------------------------------------

set -e
set -o pipefail

# ---------- Colors ----------
BOLD=$(tput bold)
RESET=$(tput sgr0)
GREEN=$(tput setaf 2)
RED=$(tput setaf 1)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)

# ---------- Logging ----------
log() {
  echo -e "${BOLD}$1${RESET}"
}

info()    { log "${BLUE}[INFO]${RESET} $1"; }
success() { log "${GREEN}[✔] $1"; }
warn()    { log "${YELLOW}[⚠] $1"; }
error()   { log "${RED}[✘] $1"; exit 1; }

# ---------- Variables ----------
VERSION="3.0.13"
ARCHIVE="openssl-${VERSION}.tar.gz"
FOLDER="openssl-${VERSION}"
EXPECTED_SUM="88525753f79d3bec27d2fa7c66aa6b1b83705549a7a3f7fcb32e587a72f9ecec"

DOWNLOAD_URLS=(
  "https://github.com/openssl/openssl/releases/download/openssl-${VERSION}/${ARCHIVE}"
  "https://ftp.openssl.org/source/${ARCHIVE}"
)

# ---------- Functions ----------
install_deps() {
  info "Installing required dependencies..."
  sudo apt update -y
  sudo apt install -y build-essential checkinstall zlib1g-dev libssl-dev wget ca-certificates perl

  # Optional: Fix missing GPG key
  sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys F57D4F59BD3DF454 || true
}

download_source() {
  info "Downloading OpenSSL $VERSION..."

  for url in "${DOWNLOAD_URLS[@]}"; do
    info "Trying: $url"
    wget -q --show-progress "$url" -O "$ARCHIVE" && break
  done

  if [ ! -f "$ARCHIVE" ]; then
    error "Failed to download $ARCHIVE from all sources."
  fi
}

verify_checksum() {
  info "Verifying checksum..."

  ACTUAL_SUM=$(sha256sum "$ARCHIVE" | awk '{print $1}')
  info "Computed checksum: $ACTUAL_SUM"

  if [ -z "$EXPECTED_SUM" ]; then
    warn "No EXPECTED_SUM set. Using computed value."
    EXPECTED_SUM="$ACTUAL_SUM"
    success "Checksum saved as: $EXPECTED_SUM"
  fi

  if [[ "$ACTUAL_SUM" != "$EXPECTED_SUM" ]]; then
    warn "Checksum mismatch!"
    warn "Expected: $EXPECTED_SUM"
    warn "Actual  : $ACTUAL_SUM"
    rm -f "$ARCHIVE"
    error "Checksum verification failed. File removed."
  else
    success "Checksum verified."
  fi
}

extract_build_install() {
  info "Extracting archive..."
  tar -xf "$ARCHIVE"

  cd "$FOLDER"

  info "Configuring..."
  ./config --prefix=/usr/local/ssl --openssldir=/usr/local/ssl shared zlib

  info "Compiling..."
  make -j"$(nproc)"

  info "Installing (with checkinstall)..."
  sudo checkinstall --pkgname=openssl-custom --pkgversion="$VERSION" --backup=no --fstrans=no --default make install

  cd ..
}

post_install() {
  info "Updating shared libraries cache..."
  echo "/usr/local/ssl/lib" | sudo tee /etc/ld.so.conf.d/openssl.conf
  sudo ldconfig

  success "OpenSSL $VERSION installation completed!"
  openssl version -a
}

cleanup() {
  info "Cleaning up..."
  rm -rf "$FOLDER" "$ARCHIVE"
  success "Done."
}

# ---------- Main Script ----------
info "Starting OpenSSL ${VERSION} installation..."
install_deps
download_source


# --------------------
#verify_checksum


extract_build_install
post_install
cleanup
