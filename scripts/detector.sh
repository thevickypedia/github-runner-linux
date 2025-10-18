#!/bin/bash
# This script is a skim of https://github.com/actions/runner/blob/c3bf70b/src/dev.sh

RUNTIME_ID="linux-x64"
CURRENT_PLATFORM="linux"
if command -v uname > /dev/null; then
    CPU_NAME=$(uname -m)
    case $CPU_NAME in
        armv7l) RUNTIME_ID="linux-arm";;
        aarch64) RUNTIME_ID="linux-arm64";;
    esac
fi
