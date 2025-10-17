#!/bin/bash

instance_id_legacy() {
  # Use randomly generated instance IDs (AWS format) as default runner names
  letters=$(tr -dc '[:lower:]' < /dev/urandom | head -c 4)
  digits=$(tr -dc '0-9' < /dev/urandom | head -c 12)
  eid=$(echo "$letters$digits" | fold -w1 | shuf | tr -d '\n')
  echo "i-0$eid"
}

instance_id() {
  # Use randomly generated instance IDs without /dev/urandom (AWS format) as default runner names
  chars=({a..z})
  digits=({0..9})
  id_parts=()

  # Add 4 random lowercase letters
  for _ in {1..4}; do
    id_parts+=("${chars[RANDOM % ${#chars[@]}]}")
  done

  # Add 12 random digits
  for _ in {1..12}; do
    id_parts+=("${digits[RANDOM % ${#digits[@]}]}")
  done

  # Shuffle the array manually
  for ((i = ${#id_parts[@]} - 1; i > 0; i--)); do
    j=$((RANDOM % (i + 1)))
    tmp=${id_parts[i]}
    id_parts[i]=${id_parts[j]}
    id_parts[j]=$tmp
  done

  eid=$(IFS=; echo "${id_parts[*]}")
  echo "i-0$eid"
}

cleanup() {
  log "Removing runner..."
  ntfy_fn "Removing runner: '${RUNNER_NAME}'"
  telegram_fn "Removing runner: '${RUNNER_NAME}'"
  ./config.sh remove --token "${REG_TOKEN}"
}
