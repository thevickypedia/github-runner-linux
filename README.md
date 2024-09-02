# GitHub Runner Linux

Build a self-hosted GitHub action runner as an Ubuntu linux container

## Development

Set latest `RUNNER_VERSION`

```shell
export RUNNER_VERSION=$(curl -sL \
      -H "Accept: application/vnd.github+json" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      https://api.github.com/repos/actions/runner/releases/latest | jq .tag_name --raw-output)
```

#### Build

```shell
docker build --build-arg RUNNER_VERSION=$RUNNER_VERSION -t runner .
```

#### Run

```shell
docker compose up -d
```

#### Exec

```shell
docker exec -it container-name sh
```
