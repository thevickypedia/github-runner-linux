# GitHub Runner Linux

[![Test Runner][badges-test]][links-test]
[![Build and Publish][badges-build]][links-build]

Spin up an on-demand self-hosted GitHub action runner with multi-arch supported Ubuntu image.

## Usage

**Docker Run**

```shell
docker run thevickypedia/github-runner-linux
```

**[Docker Compose][docker-compose]**

```shell
docker compose up -d
```

### Environment Variables

- **GIT_TOKEN** - Required for authentication to add runners.
- **GIT_OWNER** - GitHub account username [OR] organization name.
- **GIT_REPOSITORY** - Repository name _(required to create runners dedicated to a particular repo)_
- **RUNNER_GROUP** - Runner group. Uses `default`
- **RUNNER_NAME** - Runner name. Uses a random instance ID.
- **WORK_DIR** - Work directory. Uses `_work`
- **LABELS** - Runner labels (comma separated). Uses `"docker-node,${os_name}-${architecture}"`
- **REUSE_EXISTING** - Re-use existing configuration. Defaults to `false`

> [!NOTE]
> `REUSE_EXISTING` flag can be useful when a container restarts due to an issue or
> when a container is reused after being terminated without shutting down gracefully.
> <details>
> <summary><strong>More info</strong></summary>
>
> Following files/directories are created (commonly across `macOS`, `Linux` and `Windows` runners)
> only when the runner has been configured 
> - `_work`
> - `_diag`
> - `.runner`
> - `.credentials`
> - `.credentials_rsaparams`
>
> So, a simple check on one or more of these files' presence should confirm if the runner has been configured already
>
> **Note:** Warnings like the ones below are common, and GitHub typically reconnects the runner automatically.
> ```text
> A session for this runner already exists.
> ```
> ```
> Runner connect error: The actions runner i-058175xh7908r2u46 already has an active session.. Retrying until reconnected.
> ```
> </details>

> [!WARNING]  
Using this image **without** the env var `GIT_REPOSITORY` will create an organization level runner.
Using self-hosted runners in public repositories pose some considerable security threats.
> - [#self-hosted-runner-security]
> - [#restricting-the-use-of-self-hosted-runners]
> - [#configuring-required-approval-for-workflows-from-public-forks]

<details>
<summary><strong>Env vars for notifications</strong></summary>

> This project supports [ntfy] and [telegram bot] for startup/shutdown notifications.

**NTFY**

Choose ntfy setup instructions with [basic][ntfy-setup-basic] **OR** [authentication][ntfy-setup-auth] abilities

- **NTFY_URL** - Ntfy endpoint for notifications.
- **NTFY_TOPIC** - Topic to which the notifications have to be sent.
- **NTFY_USERNAME** - Ntfy username for authentication _(if topic is protected)_
- **NTFY_PASSWORD** - Ntfy password for authentication _(if topic is protected)_

**Telegram**

Steps for telegram bot configuration

1. Use [BotFather] to create a telegram bot token
2. Send a test message to the Telegram bot you created
3. Use the URL https://api.telegram.org/bot{token}/getUpdates to get the Chat ID
   - You can also use Thread ID to send notifications to a particular thread within a group

```shell
export TELEGRAM_BOT_TOKEN="your-bot-token"
export CHAT_ID=$(curl -s "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getUpdates" | jq -r '.result[0].message.chat.id')
```

- **TELEGRAM_BOT_TOKEN** - Telegram Bot token
- **TELEGRAM_CHAT_ID** - Chat ID to which the notifications have to be sent.
- **THREAD_ID** - Optional thread ID to send notifications to a specific thread.

> **Note:** To send notifications to threads, the bot should be added to a group with [Topics][telegram-topics] enabled.<br>
> Send a message to the bot in a group thread
> ```shell
> export THREAD_ID=$(curl -s "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getUpdates" | jq -r '.result[0]|.update_id')
> ```

</details>

## Development

Set latest `RUNNER_VERSION`

```shell
RUNNER_VERSION=$(curl -sL \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/repos/actions/runner/releases/latest | jq .tag_name --raw-output)

export RUNNER_VERSION="${RUNNER_VERSION#?}"
```

#### Build

```shell
docker build --build-arg RUNNER_VERSION=$RUNNER_VERSION -t runner .
```

[badges-test]: https://github.com/thevickypedia/github-runner-linux/actions/workflows/test.yml/badge.svg
[links-test]: https://github.com/thevickypedia/github-runner-linux/actions/workflows/test.yml
[badges-build]: https://github.com/thevickypedia/github-runner-linux/actions/workflows/main.yml/badge.svg
[links-build]: https://github.com/thevickypedia/github-runner-linux/actions/workflows/main.yml
[docker-compose]: https://github.com/thevickypedia/github-runner-linux/blob/main/docker-compose.yml
[ntfy]: https://ntfy.sh/
[telegram bot]: https://core.telegram.org/bots/api
[ntfy-setup-basic]: https://docs.ntfy.sh/install/
[ntfy-setup-auth]: https://community.home-assistant.io/t/setting-up-private-and-secure-ntfy-messaging-for-ha-notifications/632952
[BotFather]: https://t.me/botfather
[telegram-topics]: https://telegram.org/blog/topics-in-groups-collectible-usernames
[telegram-threads]: https://core.telegram.org/api/threads

[#restricting-the-use-of-self-hosted-runners]: https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/about-self-hosted-runners#restricting-the-use-of-self-hosted-runners
[#self-hosted-runner-security]: https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/about-self-hosted-runners#self-hosted-runner-security
[#configuring-required-approval-for-workflows-from-public-forks]: https://docs.github.com/en/organizations/managing-organization-settings/disabling-or-limiting-github-actions-for-your-organization#configuring-required-approval-for-workflows-from-public-forks
