FROM ubuntu:22.04

SHELL ["/bin/bash", "-c"]

ENV DEBIAN_FRONTEND=noninteractive
ENV HOME="/home/docker"

# Set top-level working directory
WORKDIR ${HOME}

# Update the base packages and install dependencies
RUN apt-get update -y && \
    apt-get upgrade -y && \
    # Install required packages
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
    python3.11 \
    python3.11-venv \
    python3.11-dev \
    python3-pip \
    nodejs \
    npm \
    golang-go && \
    # Create a non-root user "docker"
    useradd -m -s /bin/bash docker && \
    # Give docker sudo rights
    usermod -aG sudo docker && \
    # Passwordless sudo for docker user
    echo "docker ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/docker && \
    # Set correct permissions for the sudoers file
    chmod 0440 /etc/sudoers.d/docker && \
    # Create a symbolic link for python pointing to python3.11
    ln -s /usr/bin/python3.11 /usr/bin/python && \
    # Install rustup
    # https://github.com/rust-lang/rustup/issues/297#issuecomment-444818896
    curl https://sh.rustup.rs -sSf | sh -s -- -y && \
    # Clean up apt cache to reduce image size
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ENV PATH="${HOME}/.cargo/bin:${PATH}"

# Copy ALL scripts make them executable
COPY scripts/* ./
RUN chmod +x *.sh && chown -R docker:docker ${HOME}

# Set the user to "docker" so all subsequent commands are run as the docker user
USER docker

# Set the entrypoint to the start.sh script
ENTRYPOINT ["./start.sh"]
