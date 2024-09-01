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

instance_id() {
  # Use randomly generated instance IDs (AWS format) as default runner names
  letters=$(tr -dc '[:lower:]' < /dev/urandom | head -c 4)
  digits=$(tr -dc '0-9' < /dev/urandom | head -c 12)
  eid=$(echo "$letters$digits" | fold -w1 | shuf | tr -d '\n')
  echo "0$eid"
}

# Env vars (docker-compose.yml)
RUNNER_NAME="${RUNNER_NAME:-"i-$(instance_id)"}"
RUNNER_GROUP="${RUNNER_GROUP:-"default"}"
WORK_DIR="${WORK_DIR:-"_work"}"
LABELS="${LABELS:-"docker-node,$os_name-$architecture"}"

repo_level_runner() {
    # https://docs.github.com/en/rest/actions/self-hosted-runners#create-a-registration-token-for-a-repository
    REG_TOKEN=$(curl -sX POST \
        -H "Accept: application/vnd.github.v3+json" \
        -H "Authorization: token ${GIT_TOKEN}" \
        "https://api.github.com/repos/${GIT_OWNER}/${GIT_REPOSITORY}/actions/runners/registration-token" \
        | jq .token --raw-output)
    cd "/home/docker/actions-runner" || exit 1
    ./config.sh --unattended \
        --work "${WORK_DIR}" \
        --labels "${LABELS}" \
        --token "${REG_TOKEN}" \
        --name "${RUNNER_NAME}" \
        --runnergroup "${RUNNER_GROUP}" \
        --url "https://github.com/${GIT_OWNER}/${GIT_REPOSITORY}"
}

org_level_runner() {
    # https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/about-self-hosted-runners#restricting-the-use-of-self-hosted-runners
    # https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/about-self-hosted-runners#self-hosted-runner-security
    # https://docs.github.com/en/rest/actions/self-hosted-runners#create-a-registration-token-for-an-organization
    REG_TOKEN=$(curl -sX POST \
        -H "Accept: application/vnd.github.v3+json" \
        -H "Authorization: token ${GIT_TOKEN}" \
        "https://api.github.com/orgs/${GIT_OWNER}/actions/runners/registration-token" \
        | jq .token --raw-output)
    cd "/home/docker/actions-runner" || exit 1
    ./config.sh \
        --work "${WORK_DIR}" \
        --labels "${LABELS}" \
        --token "${REG_TOKEN}" \
        --name "${RUNNER_NAME}" \
        --runnergroup "${RUNNER_GROUP}" \
        --url "https://github.com/${GIT_OWNER}"
}

if [ -n "${GIT_REPOSITORY}" ]; then
    echo "Creating repository level self-hosted runner ['${RUNNER_NAME}'] for ${GIT_REPOSITORY}"
    repo_level_runner
else
    echo "Creating organization level self-hosted runner '${RUNNER_NAME}'"
    org_level_runner
fi

cleanup() {
    echo "Removing runner..."
    ./config.sh remove --token "${REG_TOKEN}"
}

trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM

./run.sh & wait $!