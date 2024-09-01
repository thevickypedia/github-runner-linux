# docker-github-runner-linux

Repository for building a self-hosted GitHub runner as a ubuntu linux container

### Build

```shell
docker build --build-arg RUNNER_VERSION=2.319.1 -t runner .
```

### Run

Set latest `RUNNER_VERSION`

```shell
export RUNNER_VERSION=$(curl -sL \
      -H "Accept: application/vnd.github+json" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      https://api.github.com/repos/actions/runner/releases/latest | jq .tag_name --raw-output)
```

```shell
docker compose up -d
```

### Exec

```shell
docker exec -it container-name sh
```
