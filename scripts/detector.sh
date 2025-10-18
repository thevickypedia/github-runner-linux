#!/bin/bash

# NOTE: `uname -m` is more accurate and universal than `arch`
# See https://en.wikipedia.org/wiki/Uname
unamem="$(uname -m)"
case $unamem in
*aarch64*|arm64)
    architecture="arm64";;
*64*)
    architecture="amd64";;
*86*)
    architecture="386";;
*armv5*)
    architecture="armv5";;
*armv6*)
    architecture="armv6";;
*armv7*)
    architecture="armv7";;
*arm*)
    architecture="arm";;
*)
    echo "Unknown architecture: $unamem"
    ;;
esac
export architecture="${architecture}"

unameu="$(tr '[:lower:]' '[:upper:]' <<< "$(uname)")"
if [[ $unameu == *DARWIN* ]]; then
    os_name="darwin"
elif [[ $unameu == *LINUX* ]]; then
    os_name="linux"
elif [[ $unameu == *FREEBSD* ]]; then
    os_name="freebsd"
elif [[ $unameu == *NETBSD* ]]; then
    os_name="netbsd"
elif [[ $unameu == *OPENBSD* ]]; then
    os_name="openbsd"
elif [[ $unameu == *WIN* || $unameu == MSYS* ]]; then
    # Should catch cygwin
    os_name="windows"
else
    echo "Unknown OS: $(uname)"
fi
export os_name="${os_name}"
export platform="${os_name}-${architecture}"

# TODO: Merge with case statements above
# Map architecture and os_name to the list used by GitHub runners
# https://github.com/actions/runner/releases

case $architecture in
"amd64")
    runner_arch="x64";;
"386")
    runner_arch="x86";;
"armv5"|"armv6"|"armv7"|"arm")
    runner_arch="arm";;
*)
    runner_arch="$architecture";;
esac
export runner_arch="${runner_arch}"

case $os_name in
"darwin")
    runner_os="osx";;
"windows")
    runner_os="win";;
*)
    runner_os="$os_name";;
esac
export runner_os="${runner_os}"
export runner_platform="${runner_os}-${runner_arch}"
