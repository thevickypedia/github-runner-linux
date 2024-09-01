# docker-github-runner-linux

Repository for building a self hosted GitHub runner as a ubuntu linux container

### Build

```
docker build --build-arg RUNNER_VERSION=2.319.1 -t runner .
```

### Run

```
docker compose up -d
```
