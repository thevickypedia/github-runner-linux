download_runner() {
    # TODO: Allow to choose specific version
    # Set GitHub Actions Runner version
    RELEASE_URL="https://github.com/actions/runner/releases"
    RUNNER_VERSION=$(curl -sL \
        -H "Accept: application/vnd.github+json" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        https://api.github.com/repos/actions/runner/releases/latest | jq .tag_name --raw-output)
    export RUNNER_VERSION=${RUNNER_VERSION#v}

    # Download and unzip the github actions runner
    rm -rf /home/docker/actions-runner
    mkdir actions-runner && cd actions-runner

    # TODO: Support other architectures
    curl -kOL ${RELEASE_URL}/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz
    sleep 2
    tar xzf ./actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz
    sleep 2

    log "Installing dependencies for the runner..."
    chmod +x bin/installdependencies.sh
    sudo ./bin/installdependencies.sh

    log "Cleaning up apt cache..."
    sudo apt-get clean
    rm -rf /var/lib/apt/lists/*
}
