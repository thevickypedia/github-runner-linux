#!/bin/bash
# This script is a skim of https://github.com/actions/runner/blob/c3bf70b/src/dev.sh

RUNTIME_ID="linux-x64"
CPU_NAME="x86_64"
if command -v uname > /dev/null; then
    CPU_NAME=$(uname -m)
    case $CPU_NAME in
        armv7l) RUNTIME_ID="linux-arm";;
        aarch64) RUNTIME_ID="linux-arm64";;
    esac
fi

# Non-dockerized builds

# CURRENT_PLATFORM="windows"
# if [[ ($(uname) == "Linux") || ($(uname) == "Darwin") ]]; then
#     CURRENT_PLATFORM=$(uname | awk '{print tolower($0)}')
# fi

# if [[ "$CURRENT_PLATFORM" == 'windows' ]]; then
#     RUNTIME_ID='win-x64'
#     if [[ "$PROCESSOR_ARCHITECTURE" == 'x86' ]]; then
#         RUNTIME_ID='win-x86'
#     fi
#     if [[ "$PROCESSOR_ARCHITECTURE" == 'ARM64' ]]; then
#         RUNTIME_ID='win-arm64'
#     fi
# elif [[ "$CURRENT_PLATFORM" == 'linux' ]]; then
#     RUNTIME_ID="linux-x64"
#     if command -v uname > /dev/null; then
#         CPU_NAME=$(uname -m)
#         case $CPU_NAME in
#             armv7l) RUNTIME_ID="linux-arm";;
#             aarch64) RUNTIME_ID="linux-arm64";;
#         esac
#     fi
# elif [[ "$CURRENT_PLATFORM" == 'darwin' ]]; then
#     RUNTIME_ID='osx-x64'
#     if command -v uname > /dev/null; then
#         CPU_NAME=$(uname -m)
#         case $CPU_NAME in
#             arm64) RUNTIME_ID="osx-arm64";;
#         esac
#     fi
# fi

# if [[ -n "$DEV_TARGET_RUNTIME" ]]; then
#     RUNTIME_ID="$DEV_TARGET_RUNTIME"
# fi

# # Make sure current platform support publish the dotnet runtime
# # Windows can publish win-x86/x64/arm64
# # Linux can publish linux-x64/arm/arm64
# # OSX can publish osx-x64/arm64
# if [[ "$CURRENT_PLATFORM" == 'windows' ]]; then
#     if [[ ("$RUNTIME_ID" != 'win-x86') && ("$RUNTIME_ID" != 'win-x64') && ("$RUNTIME_ID" != 'win-arm64') ]]; then
#         echo "Failed: Can't build $RUNTIME_ID package $CURRENT_PLATFORM" >&2
#         exit 1
#     fi
# elif [[ "$CURRENT_PLATFORM" == 'linux' ]]; then
#     if [[ ("$RUNTIME_ID" != 'linux-x64') && ("$RUNTIME_ID" != 'linux-x86') && ("$RUNTIME_ID" != 'linux-arm64') && ("$RUNTIME_ID" != 'linux-arm') ]]; then
#        echo "Failed: Can't build $RUNTIME_ID package $CURRENT_PLATFORM" >&2
#        exit 1
#     fi
# elif [[ "$CURRENT_PLATFORM" == 'darwin' ]]; then
#     if [[ ("$RUNTIME_ID" != 'osx-x64') && ("$RUNTIME_ID" != 'osx-arm64') ]]; then
#        echo "Failed: Can't build $RUNTIME_ID package $CURRENT_PLATFORM" >&2
#        exit 1
#     fi
# fi
