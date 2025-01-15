FROM ubuntu:22.04

SHELL ["/bin/bash", "-c"]

ARG RUNNER_VERSION
ENV RUNNER_VERSION="${RUNNER_VERSION:-2.319.1}"
ENV DEBIAN_FRONTEND=noninteractive
ENV HOME="/home/docker"
ENV RELEASE_URL="https://github.com/actions/runner/releases"

# Set top-level working directory
WORKDIR ${HOME}

# Update the base packages and add a non-sudo user
RUN apt-get update -y && \
    apt-get upgrade -y && \
    useradd -m docker

# Install the packages and dependencies
RUN apt-get install -y --no-install-recommends \
    curl \
    wget \
    unzip \
    vim \
    git \
    jq \
    findutils \
    build-essential \
    libssl-dev \
    libffi-dev \
    python3.10 \
    python3.10-venv \
    python3.10-dev \
    python3-pip \
    nodejs \
    npm \
    golang-go

# Create a symbolic link for python pointing to python3.10
RUN ln -s /usr/bin/python3.10 /usr/bin/python

# https://github.com/rust-lang/rustup/issues/297#issuecomment-444818896
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y
ENV PATH="${HOME}/.cargo/bin:${PATH}"

# Find OpenSSL paths, set environment variables, and persist them
RUN OPENSSL_LIB_PATH=$(find / -name 'libssl.so*' 2>/dev/null | head -n 1) && \
    OPENSSL_LIB_DIR=$(dirname "$OPENSSL_LIB_PATH") && \
    OPENSSL_INCLUDE_PATH=$(find /usr -name 'ssl.h' 2>/dev/null | grep -v '/node/' | head -n 1) && \
    OPENSSL_INCLUDE_DIR=$(dirname "$OPENSSL_INCLUDE_PATH") && \
    echo "OPENSSL_LIB_DIR=$OPENSSL_LIB_DIR" && \
    echo "OPENSSL_INCLUDE_DIR=$OPENSSL_INCLUDE_DIR" && \
    echo "OPENSSL_STATIC=$OPENSSL_STATIC" && \
    export OPENSSL_LIB_DIR OPENSSL_INCLUDE_DIR

# Set the environment variables for future stages (persistent across containers)
ENV OPENSSL_LIB_DIR=$OPENSSL_LIB_DIR \
    OPENSSL_INCLUDE_DIR=$OPENSSL_INCLUDE_DIR \
    OPENSSL_STATIC=1

# Download and unzip the github actions runner
RUN mkdir actions-runner && cd actions-runner \
    && curl -O -L ${RELEASE_URL}/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz \
    && tar xzf ./actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz

# Install additional dependencies
RUN chown -R docker ~docker && /home/docker/actions-runner/bin/installdependencies.sh

# Copy ALL scripts make them executable
COPY scripts/* .
RUN chmod +x *.sh

# Set the user to "docker" so all subsequent commands are run as the docker user
USER docker

# Set the entrypoint to the start.sh script
ENTRYPOINT ["./start.sh"]
