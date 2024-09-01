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

unameu="$(tr '[:lower:]' '[:upper:]' <<<$(uname))"
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

DEFAULT_LABEL="$os_name-$architecture"

RUNNER_SUFFIX=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 5 | head -n 1)
RUNNER_NAME="docker-node-${RUNNER_SUFFIX}"

# Env vars (docker-compose.yml)
RUNNER_GROUP="${RUNNER_GROUP:-default}"
WORK_DIR="${WORK_DIR:-_work}"
LABELS="${LABELS:-$DEFAULT_LABEL}"

if [ -n "${GIT_REPOSITORY}" ]; then
    echo "Creating repository level self-hosted runner ['${RUNNER_NAME}'] for ${GIT_REPOSITORY}"
    # https://docs.github.com/en/rest/actions/self-hosted-runners#create-a-registration-token-for-a-repository
    REG_TOKEN=$(curl -sX POST \
            -H "Accept: application/vnd.github.v3+json" \
            -H "Authorization: token ${GIT_TOKEN}" \
            "https://api.github.com/repos/${GIT_OWNER}/${GIT_REPOSITORY}/actions/runners/registration-token" \
            | jq .token --raw-output)

    cd /home/docker/actions-runner

    ./config.sh --unattended \
        --work "${WORK_DIR}" \
        --labels "${LABELS}" \
        --token "${REG_TOKEN}" \
        --name "${RUNNER_NAME}" \
        --runnergroup "${RUNNER_GROUP}" \
        --url "https://github.com/${GIT_OWNER}/${GIT_REPOSITORY}"
else
    echo "Creating organization level self-hosted runner '${RUNNER_NAME}'"
    # https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/about-self-hosted-runners#restricting-the-use-of-self-hosted-runners
    # https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/about-self-hosted-runners#self-hosted-runner-security
    # https://docs.github.com/en/rest/actions/self-hosted-runners#create-a-registration-token-for-an-organization
    REG_TOKEN=$(curl -sX POST \
            -H "Accept: application/vnd.github.v3+json" \
            -H "Authorization: token ${GIT_TOKEN}" \
            "https://api.github.com/orgs/${GIT_OWNER}/actions/runners/registration-token" \
            | jq .token --raw-output)

    cd /home/docker/actions-runner

    ./config.sh \
        --work "${WORK_DIR}" \
        --labels "${LABELS}" \
        --token "${REG_TOKEN}" \
        --name "${RUNNER_NAME}" \
        --runnergroup "${RUNNER_GROUP}" \
        --url "https://github.com/${GIT_OWNER}"
fi

cleanup() {
    echo "Removing runner..."
    ./config.sh remove --unattended --token ${REG_TOKEN}
}

trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM

./run.sh & wait $!