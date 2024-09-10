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

log() {
  dt_stamp=$(date -u +"%Y-%m-%d %H:%M:%SZ")
  echo "${dt_stamp}: $1"
}

instance_id() {
  # Use randomly generated instance IDs (AWS format) as default runner names
  letters=$(tr -dc '[:lower:]' < /dev/urandom | head -c 4)
  digits=$(tr -dc '0-9' < /dev/urandom | head -c 12)
  eid=$(echo "$letters$digits" | fold -w1 | shuf | tr -d '\n')
  echo "i-0$eid"
}

# Env vars (docker-compose.yml)
RUNNER_NAME="${RUNNER_NAME:-"$(instance_id)"}"
RUNNER_GROUP="${RUNNER_GROUP:-"default"}"
WORK_DIR="${WORK_DIR:-"_work"}"
LABELS="${LABELS:-"docker-node,$os_name-$architecture"}"
REUSE_EXISTING="${REUSE_EXISTING:-"false"}"
NOTIFICATION_TITLE="GitHub Actions Runner - Docker Node"

ntfy_fn() {
  # Send NTFY notification
  body="$1"

  if [[ -n "$NTFY_TOPIC" && -n "$NTFY_URL" ]]; then
    # Remove trailing '/' if present
    # https://github.com/binwiederhier/ntfy/issues/370
    NTFY_URL=${NTFY_URL%/}
    response=$(curl -s -o /tmp/ntfy -w "%{http_code}" -X POST \
              -u "$NTFY_USERNAME:$NTFY_PASSWORD" \
              -H "X-Title: ${NOTIFICATION_TITLE}" \
              -H "Content-Type: application/x-www-form-urlencoded" \
              --data "${body}" \
              "$NTFY_URL/$NTFY_TOPIC")
    status_code="${response: -3}"
    if [ "$status_code" -eq 200 ]; then
      log "Ntfy notification was successful"
    elif [[ -f "/tmp/ntfy" ]]; then
      log "Failed to send ntfy notification"
      response_payload="$(cat /tmp/ntfy)"
      reason=$(echo "$response_payload" | jq '.error')
      # Output the extracted description or the full response if jq fails
      if [ "$reason" != "null" ]; then
          log "[$status_code]: $reason"
      else
          log "[$status_code]: $(cat /tmp/ntfy)"
      fi
    else
      log "Failed to send ntfy notification - ${status_code}"
    fi
    rm -f /tmp/ntfy
  else
    log "Ntfy notifications is not setup"
  fi
}

telegram_fn() {
  # Send Telegram notification
  body="$1"

  if [[ -n "$TELEGRAM_BOT_TOKEN" && -n "$TELEGRAM_CHAT_ID" ]]; then
    notification_preference=${DISABLE_TELEGRAM_NOTIFICATION:-false}

    # Base JSON payload
    message=$(printf "*%s*\n\n%s" "${NOTIFICATION_TITLE}" "${body}")
    payload=$(jq -n \
      --arg chat_id "$TELEGRAM_CHAT_ID" \
      --arg text "$message" \
      --arg parse_mode "markdown" \
      --arg disable_notification "$notification_preference" \
      '{
        chat_id: $chat_id,
        text: $text,
        parse_mode: $parse_mode,
        disable_notification: $disable_notification
      }')

    # Add 'message_thread_id' if TELEGRAM_THREAD_ID is available and not null
    if [ -n "$TELEGRAM_THREAD_ID" ]; then
      payload=$(echo "$payload" | jq --arg thread_id "$TELEGRAM_THREAD_ID" '. + {message_thread_id: $thread_id}')
    fi

    response=$(curl -s -o /tmp/telegram -w "%{http_code}" -X POST \
              -H 'Content-Type: application/json' \
              -d "$payload" \
              "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage")
    status_code="${response: -3}"
    if [ "$status_code" -eq 200 ]; then
      log "Telegram notification was successful"
    elif [[ -f "/tmp/telegram" ]]; then
      log "Failed to send telegram notification"
      response_payload="$(cat /tmp/telegram)"
      reason=$(echo "$response_payload" | jq '.description')
      # Output the extracted description or the full response if jq fails
      if [ "$reason" != "null" ]; then
          log "[$status_code]: $reason"
      else
          log "[$status_code]: $(cat /tmp/telegram)"
      fi
    else
      log "Failed to send telegram notification - ${status_code}"
    fi
    rm -f /tmp/telegram
  else
    log "Telegram notifications is not setup"
  fi
}

repo_level_runner() {
    # https://docs.github.com/en/rest/actions/self-hosted-runners#create-a-registration-token-for-a-repository
    REG_TOKEN=$(curl -sX POST \
        -H "Accept: application/vnd.github.v3+json" \
        -H "Authorization: Bearer ${GIT_TOKEN}" \
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
        -H "Authorization: Bearer ${GIT_TOKEN}" \
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

cleanup() {
  log "Removing runner..."
  ntfy_fn "Removing runner: '${RUNNER_NAME}'"
  telegram_fn "Removing runner: '${RUNNER_NAME}'"
  ./config.sh remove --token "${REG_TOKEN}"
}

trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM

ntfy_fn "Starting GitHub actions runner: '${RUNNER_NAME}' using docker node by ${reused}" &
telegram_fn "Starting GitHub actions runner: '${RUNNER_NAME}' using docker node by ${reused}" &

./run.sh & wait $!
