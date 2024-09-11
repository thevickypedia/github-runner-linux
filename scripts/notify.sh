#!/bin/bash

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
