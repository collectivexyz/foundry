ARG IMAGE_VERSION
ARG TARGETARCH

# Stage 1: Build yamlfmt
FROM golang:1 AS go-builder
# defined from build kit
# DOCKER_BUILDKIT=1 docker build . -t ...
ARG ETH_VERSION=1.14.12

# Install yamlfmt
WORKDIR /yamlfmt
RUN go install github.com/google/yamlfmt/cmd/yamlfmt@latest && \
    strip $(which yamlfmt) && \
    yamlfmt --version

## Go Ethereum
WORKDIR /go-ethereum

ADD https://github.com/ethereum/go-ethereum/archive/refs/tags/v${ETH_VERSION}.tar.gz /go-ethereum/go-ethereum-${ETH_VERSION}.tar.gz
RUN echo 'SHA256 of this go-ethereum package...'
RUN cat /go-ethereum/go-ethereum-${ETH_VERSION}.tar.gz | sha256sum 
RUN tar -zxf go-ethereum-${ETH_VERSION}.tar.gz  -C /go-ethereum
WORKDIR /go-ethereum/go-ethereum-${ETH_VERSION}
RUN go mod download 
RUN go run build/ci.go install

# Use the build argument in the FROM statement
FROM debian:$IMAGE_VERSION AS foundry-builder

# Example build steps
RUN echo "Using Debian version: ${IMAGE_VERSION}"
# defined from build kit
# DOCKER_BUILDKIT=1 docker build . -t ...

RUN export DEBIAN_FRONTEND=noninteractive && \
    apt-get update && \
    apt-get install -y -q --no-install-recommends \
      ca-certificates \
      curl \
      git \
      gnupg2 \
      openssl \
      pkg-config \
      python3 \
    && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN useradd --create-home -s /bin/bash foundry
RUN usermod -a -G sudo foundry
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

WORKDIR /rustup
## Rust
ADD https://sh.rustup.rs /rustup/rustup.sh
RUN chmod 555 /rustup/rustup.sh

## FoundryUp
ADD https://foundry.paradigm.xyz /rustup/foundryup.sh
RUN chmod 555 /rustup/foundryup.sh

ENV USER=foundry
USER foundry
RUN /rustup/rustup.sh -y --default-toolchain stable --profile minimal

# latest https://github.com/foundry-rs/foundry
ENV PATH=$PATH:~foundry/.cargo/bin

## Foundry
WORKDIR /build/foundry
RUN /rustup/foundryup.sh

# Use the build argument in the FROM statement
FROM debian:${IMAGE_VERSION} AS node-slim

# Example build steps
RUN echo "Using Debian version: ${IMAGE_VERSION}"

RUN export DEBIAN_FRONTEND=noninteractive && \
    apt-get update && \
    apt-get install -y -q --no-install-recommends \
      build-essential \
      ca-certificates \
      curl \
      git \
      gnupg2 \
    && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN mkdir -p /usr/local/nvm
ENV NVM_DIR=/usr/local/nvm

ENV NODE_VERSION=v22.12.0

RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash
RUN bash -c ". $NVM_DIR/nvm.sh && nvm install $NODE_VERSION && nvm alias default $NODE_VERSION && nvm use default"

ENV NVM_NODE_PATH ${NVM_DIR}/versions/node/${NODE_VERSION}
ENV NODE_PATH ${NVM_NODE_PATH}/lib/node_modules
ENV PATH      ${NVM_NODE_PATH}/bin:$PATH

RUN npm install npm -g
RUN npm install yarn -g

FROM node-slim

ARG ETH_VERSION=1.14.12

RUN export DEBIAN_FRONTEND=noninteractive && \
  apt-get update && \
  apt-get install -y -q --no-install-recommends \
    libz3-dev \
    openssh-client \
    procps \
    python3 \
    python3-dev \
    python3-pip \
    ripgrep \
    sudo \
    z3 \
    && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN echo "building platform $(uname -m)"

RUN useradd --create-home -s /bin/bash foundry
RUN usermod -a -G sudo foundry
RUN echo '%foundry ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# SOLC
COPY --from=ghcr.io/jac18281828/solc:latest /usr/local/bin/solc /usr/local/bin
COPY --from=ghcr.io/jac18281828/solc:latest /usr/local/bin/yul-phaser /usr/local/bin
RUN solc --version

## Rust 
COPY --chown=foundry:foundry --from=foundry-builder /home/foundry/.cargo /home/foundry/.cargo

# GO LANG
COPY --from=go-builder /go /go

## GO Ethereum Binaries
COPY --from=go-builder /go-ethereum/go-ethereum-${ETH_VERSION}/build/bin /usr/local/bin

# Foundry Up
ENV USER=foundry
USER foundry
ENV FOUNDRY_INSTALL_DIR=/home/${USER}/.foundry
COPY --from=foundry-builder ${FOUNDRY_INSTALL_DIR} ${FOUNDRY_INSTALL_DIR}
ENV PATH=${PATH}:${FOUNDRY_INSTALL_DIR}/bin:/go/bin
RUN foundryup

RUN strip ${FOUNDRY_INSTALL_DIR}/bin/forge
RUN strip ${FOUNDRY_INSTALL_DIR}/bin/cast
RUN strip ${FOUNDRY_INSTALL_DIR}/bin/anvil
RUN strip ${FOUNDRY_INSTALL_DIR}/bin/chisel

LABEL org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.name="foundry" \
    org.label-schema.description="Foundry RS Development Container" \
    org.label-schema.url="https://github.com/collectivexyz/foundry" \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url="git@github.com:collectivexyz/foundry.git" \
    org.label-schema.vendor="Collective" \
    org.label-schema.version=$VERSION \
    org.label-schema.schema-version="1.0" \
    org.opencontainers.image.description="Foundry and Ethereum Development Container for Visual Studio Code"
