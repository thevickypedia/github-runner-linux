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
- **GIT_REPOSITORY** - Repository name (required to create runners dedicated to a particular repo)
- **RUNNER_GROUP** - Runner group. Uses `default`
- **RUNNER_NAME** - Runner name. Uses a random instance ID.
- **WORK_DIR** - Work directory. Uses `_work`
- **LABELS** - Runner labels (comma separated). Uses `"docker-node,${os_name}-${architecture}"`

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
