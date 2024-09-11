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

cleanup() {
  log "Removing runner..."
  ntfy_fn "Removing runner: '${RUNNER_NAME}'"
  telegram_fn "Removing runner: '${RUNNER_NAME}'"
  ./config.sh remove --token "${REG_TOKEN}"
}
