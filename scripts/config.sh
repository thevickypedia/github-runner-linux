#!/bin/bash

repo_level_runner() {
    # https://docs.github.com/en/rest/actions/self-hosted-runners#create-a-registration-token-for-a-repository
    REG_TOKEN=$(curl -sX POST \
        -H "Accept: application/vnd.github.v3+json" \
        -H "Authorization: Bearer ${GIT_TOKEN}" \
        "${GITHUB_API_URL}/repos/${GIT_OWNER}/${GIT_REPOSITORY}/actions/runners/registration-token" \
        | jq .token --raw-output)
    ./config.sh --unattended \
        --work "${WORK_DIR}" \
        --labels "${LABELS}" \
        --token "${REG_TOKEN}" \
        --name "${RUNNER_NAME}" \
        --runnergroup "${RUNNER_GROUP}" \
        --url "${GITHUB_SERVER_URL}/${GIT_OWNER}/${GIT_REPOSITORY}"
}

org_level_runner() {
    # https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/about-self-hosted-runners#restricting-the-use-of-self-hosted-runners
    # https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/about-self-hosted-runners#self-hosted-runner-security
    # https://docs.github.com/en/rest/actions/self-hosted-runners#create-a-registration-token-for-an-organization
    REG_TOKEN=$(curl -sX POST \
        -H "Accept: application/vnd.github.v3+json" \
        -H "Authorization: Bearer ${GIT_TOKEN}" \
        "${GITHUB_API_URL}/orgs/${GIT_OWNER}/actions/runners/registration-token" \
        | jq .token --raw-output)
    ./config.sh \
        --work "${WORK_DIR}" \
        --labels "${LABELS}" \
        --token "${REG_TOKEN}" \
        --name "${RUNNER_NAME}" \
        --runnergroup "${RUNNER_GROUP}" \
        --url "${GITHUB_SERVER_URL}/${GIT_OWNER}"
}
