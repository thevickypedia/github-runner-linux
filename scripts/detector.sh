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
