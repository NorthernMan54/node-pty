#!/usr/bin/env bash
# Test the linux-arm cross-compilation locally using Docker.
# Mirrors the 1es-ubuntu-22.04-x64 Azure Pipelines environment.
#
# Usage:
#   ./scripts/test-linux-arm-build.sh
#
# Requirements:
#   - Docker running locally

set -eo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> Testing linux-arm cross-compilation in Ubuntu 22.04 container"
echo "    Repo: $REPO_ROOT"
echo ""

docker run --rm \
  --platform linux/amd64 \
  -v "$REPO_ROOT:/workspace" \
  -w /workspace \
  ubuntu:22.04 \
  bash -c '
    set -eo pipefail

    echo "--- Installing Node.js 22.x ---"
    apt-get update -qq
    apt-get install -y curl ca-certificates build-essential python3 file binutils
    curl -fsSL https://deb.nodesource.com/setup_22.x | bash - > /dev/null
    apt-get install -y nodejs

    echo "--- Node/npm versions ---"
    node --version
    npm --version

    echo "--- Installing arm cross-compiler (gcc-arm-linux-gnueabihf) ---"
    apt-get install -y gcc-arm-linux-gnueabihf g++-arm-linux-gnueabihf

    echo "--- Running npm ci (cross-compiling for arm) ---"
    export CC=arm-linux-gnueabihf-gcc
    export CXX=arm-linux-gnueabihf-g++
    export ARCH=arm
    export npm_config_arch=arm
    npm ci

    echo ""
    echo "--- Build output ---"
    file build/Release/pty.node
    file build/Release/spawn-helper

    echo ""
    echo "--- Verifying ELF architecture ---"
    readelf -h build/Release/pty.node | grep -E "Class|Machine|Type"

    echo ""
    echo "SUCCESS: linux-arm build completed"
  '
