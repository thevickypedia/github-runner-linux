#!/bin/bash
# 'set -e' stops the execution of a script if a command or pipeline has an error.
# This is the opposite of the default shell behaviour, which is to ignore errors in scripts.
set -e

# Set defaults
os_name=""
architecture=""

# Get to the current directory
current_dir="$(dirname "$(realpath "$0")")"
source "${current_dir}/detector.sh"
source "${current_dir}/config.sh"
source "${current_dir}/notify.sh"
source "${current_dir}/squire.sh"

# Env vars (docker-compose.yml)
RUNNER_NAME="${RUNNER_NAME:-"$(instance_id)"}"
RUNNER_GROUP="${RUNNER_GROUP:-"default"}"
WORK_DIR="${WORK_DIR:-"_work"}"
LABELS="${LABELS:-"docker-node,$os_name-$architecture"}"
REUSE_EXISTING="${REUSE_EXISTING:-"false"}"

if [[ "$REUSE_EXISTING" == "true" || "$REUSE_EXISTING" == "1" ]] &&
   [[ -d "/home/docker/actions-runner" ]] &&
   [[ -f "/home/docker/actions-runner/.credentials" ]] &&
   [[ -f "/home/docker/actions-runner/.credentials_rsaparams" ]] &&
   [[ -f "/home/docker/actions-runner/config.sh" ]] &&
   [[ -f "/home/docker/actions-runner/run.sh" ]]; then
    log "Existing configuration found. Re-using it..."
    reused="reusing existing configuration"
    cd "/home/docker/actions-runner" || exit 1
else
  if [[ -n "$GIT_REPOSITORY" ]]; then
    log "Creating a repository level self-hosted runner ['${RUNNER_NAME}'] for ${GIT_REPOSITORY}"
    repo_level_runner
  else
    log "Creating an organization level self-hosted runner '${RUNNER_NAME}'"
    org_level_runner
  fi
  reused="creating a new configuration"
fi

trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM

ntfy_fn "Starting GitHub actions runner: '${RUNNER_NAME}' using docker node by ${reused}" &
telegram_fn "Starting GitHub actions runner: '${RUNNER_NAME}' using docker node by ${reused}" &

./run.sh & wait $!
