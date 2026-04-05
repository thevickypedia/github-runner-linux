FROM ubuntu:22.04

SHELL ["/bin/bash", "-c"]

ENV DEBIAN_FRONTEND=noninteractive
ENV HOME="/home/docker"

# ---- Build arguments (override with --build-arg) ----
ARG NODE_VERSION=24
ARG PYTHON_VERSION=3.11.8
ARG GO_VERSION=1.25.4
ARG RUST_VERSION=stable

# Export to environment
ENV NODE_VERSION=${NODE_VERSION}
ENV PYTHON_VERSION=${PYTHON_VERSION}
ENV GO_VERSION=${GO_VERSION}
ENV RUST_VERSION=${RUST_VERSION}

WORKDIR ${HOME}

# ---- Base dependencies ----
RUN apt-get update -y && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    sudo \
    curl \
    wget \
    unzip \
    vim \
    gh \
    git \
    jq \
    build-essential \
    libssl-dev \
    libffi-dev \
    ca-certificates \
    gnupg \
    lsb-release && \
    rm -rf /var/lib/apt/lists/*

# ---- Create non-root user ----
RUN useradd -m -s /bin/bash docker && \
    usermod -aG sudo docker && \
    echo "docker ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/docker && \
    chmod 0440 /etc/sudoers.d/docker

# ---- Python (APT-based, major.minor only) ----
# Extract major.minor (e.g. 3.11 from 3.11.8)
RUN PYTHON_MM=$(echo ${PYTHON_VERSION} | cut -d. -f1,2) && \
    apt-get update && \
    apt-get install -y \
        python${PYTHON_MM} \
        python${PYTHON_MM}-venv \
        python${PYTHON_MM}-dev && \
    ln -sf /usr/bin/python${PYTHON_MM} /usr/bin/python && \
    ln -sf /usr/bin/pip3 /usr/bin/pip && \
    rm -rf /var/lib/apt/lists/*

# ---- Install Node.js ----
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - && \
    apt-get install -y nodejs && \
    corepack enable && \
    corepack prepare pnpm@latest --activate

# ---- Install Go ----
RUN wget https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz && \
    rm -rf /usr/local/go && \
    tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz && \
    rm go${GO_VERSION}.linux-amd64.tar.gz

ENV PATH="/usr/local/go/bin:${PATH}"

# ---- Install Rust ----
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y --default-toolchain ${RUST_VERSION}

ENV PATH="${HOME}/.cargo/bin:${PATH}"

# ---- Copy scripts ----
COPY scripts/* ./
RUN chmod +x *.sh && \
    ./image.sh && \
    chown -R docker:docker ${HOME}

# ---- Switch user ----
USER docker

ENTRYPOINT ["./start.sh"]
