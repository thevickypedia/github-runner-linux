#!/bin/bash

log "Fetching latest GitHub Actions Runner version..."
export LATEST_RUNNER_VERSION=$(curl -sL \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    https://api.github.com/repos/actions/runner/releases/latest | jq .tag_name --raw-output)
log "Latest version is: ${LATEST_RUNNER_VERSION}"

latest_runner() {
    if [ ! -f ./actions-runner/bin/Runner.Listener ]; then
        log "GitHub Actions Runner is not installed."
        return 1
    fi
    # Outputs without the 'v' prefix
    CURRENT_VERSION=$(./actions-runner/bin/Runner.Listener --version)
    log "Current GitHub Actions Runner version is: ${CURRENT_VERSION}"
    if [ "${CURRENT_VERSION}" != "${LATEST_RUNNER_VERSION#v}" ]; then
        log "A new version of GitHub Actions Runner is available."
        return 1
    fi
    log "GitHub Actions Runner is up to date."
    # Return true
    return 0
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

    log "Installing dependencies for the runner..."
    chmod +x bin/installdependencies.sh
    sudo ./bin/installdependencies.sh

    log "Cleaning up apt cache..."
    sudo apt-get clean
    sudo rm -rf /var/lib/apt/lists/*
    rm -f ${archive}
}
