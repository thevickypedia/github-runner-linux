#!/bin/bash

log "Fetching latest GitHub Actions Runner version..."
export LATEST_RUNNER_VERSION=$(curl -sL \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    https://api.github.com/repos/actions/runner/releases/latest | jq .tag_name --raw-output)
log "Latest version is: ${LATEST_RUNNER_VERSION}"

download_required() {
    if [ "${FORCE_REBUILD:-false}" = "true" ]; then
        log "Force rebuild is set. Download required."
        return 0
    fi
    if [ ! -f ./actions-runner/bin/Runner.Listener ]; then
        log "GitHub Actions Runner is not installed."
        return 0
    fi
    # Outputs without the 'v' prefix
    CURRENT_VERSION=$(./actions-runner/bin/Runner.Listener --version)
    # check if both current and latest versions are set
    if [ -z "${CURRENT_VERSION}" ] || [ -z "${LATEST_RUNNER_VERSION}" ]; then
        log "Could not determine current or latest runner version."
        log "Current: '${CURRENT_VERSION}', Latest: '${LATEST_RUNNER_VERSION}'"
        return 0
    fi
    log "Current GitHub Actions Runner version is: ${CURRENT_VERSION}"
    if [ "${CURRENT_VERSION}" != "${LATEST_RUNNER_VERSION#v}" ]; then
        log "A new version of GitHub Actions Runner is available."
        return 0
    fi
    log "GitHub Actions Runner is up to date."
    # Return false
    return 1
}

download_runner() {
    # Set GitHub Actions Runner version
    RELEASE_URL="https://github.com/actions/runner/releases"
    export RUNNER_VERSION=${LATEST_RUNNER_VERSION#v}

    # Download and unzip the github actions runner
    rm -rf /home/docker/actions-runner
    mkdir actions-runner && cd actions-runner

    archive="actions-runner-${RUNTIME_ID}-${RUNNER_VERSION}.tar.gz"
    log "Downloading GitHub Actions Runner version: ${RUNNER_VERSION} as ${archive} ..."
    curl -kOL ${RELEASE_URL}/download/v${RUNNER_VERSION}/${archive}
    sleep 2
    tar xzf ./${archive}
    sleep 2

    user_id=`id -u`
    if [ $user_id -ne 0 ]; then
        log "non-root [${whoami}:${user_id}] user, skipping dependency installation."
    else
        log "Installing dependencies for the runner..."
        chmod +x bin/installdependencies.sh
        sudo ./bin/installdependencies.sh
    fi

    log "Cleaning up apt cache..."
    sudo apt-get clean
    sudo rm -rf /var/lib/apt/lists/*
    rm -f ${archive}
}
