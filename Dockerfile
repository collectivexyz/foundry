# Stage 1: Build yamlfmt
FROM golang:1 AS go-builder
# defined from build kit
# DOCKER_BUILDKIT=1 docker build . -t ...
ARG TARGETARCH

# Install yamlfmt
WORKDIR /yamlfmt
RUN go install github.com/google/yamlfmt/cmd/yamlfmt@latest && \
    strip $(which yamlfmt) && \
    yamlfmt --version

## Go Ethereum
WORKDIR /go-ethereum
ARG ETH_VERSION=1.14.11
ADD https://github.com/ethereum/go-ethereum/archive/refs/tags/v${ETH_VERSION}.tar.gz /go-ethereum/go-ethereum-${ETH_VERSION}.tar.gz
RUN echo 'SHA256 of this go-ethereum package...'
RUN cat /go-ethereum/go-ethereum-${ETH_VERSION}.tar.gz | sha256sum 
RUN tar -zxf go-ethereum-${ETH_VERSION}.tar.gz  -C /go-ethereum
WORKDIR /go-ethereum/go-ethereum-${ETH_VERSION}
RUN go mod download 
RUN go run build/ci.go install

FROM debian:stable-slim as foundry-builder
# defined from build kit
# DOCKER_BUILDKIT=1 docker build . -t ...
ARG TARGETARCH
ARG MAXIMUM_THREADS=2
ARG CARGO_INCREMENTAL=0

RUN export DEBIAN_FRONTEND=noninteractive && \
    apt update && \
    apt install -y -q --no-install-recommends \
    git curl gnupg2 build-essential \
    linux-headers-${TARGETARCH} libc6-dev \ 
    openssl libssl-dev pkg-config \
    ca-certificates apt-transport-https \
    python3 && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*

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

FROM debian:stable-slim as node18-slim

RUN export DEBIAN_FRONTEND=noninteractive && \
    apt update && \
    apt install -y -q --no-install-recommends \
    build-essential git gnupg2 curl \
    ca-certificates apt-transport-https && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /usr/local/nvm
ENV NVM_DIR=/usr/local/nvm

ENV NODE_VERSION=v22.11.0

RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash
RUN bash -c ". $NVM_DIR/nvm.sh && nvm install $NODE_VERSION && nvm alias default $NODE_VERSION && nvm use default"

ENV NVM_NODE_PATH ${NVM_DIR}/versions/node/${NODE_VERSION}
ENV NODE_PATH ${NVM_NODE_PATH}/lib/node_modules
ENV PATH      ${NVM_NODE_PATH}/bin:$PATH

RUN npm install npm -g
RUN npm install yarn -g

FROM node18-slim
ARG TARGETARCH

RUN export DEBIAN_FRONTEND=noninteractive && \
  apt update && \
  apt install -y -q --no-install-recommends \
    libz3-dev z3 build-essential \
    ca-certificates apt-transport-https \
    sudo ripgrep procps openssh-client \
    python3 python3-pip python3-dev && \
  apt clean && \
  rm -rf /var/lib/apt/lists/*

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
ARG ETH_VERSION=1.14.11
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

RUN yamlfmt -lint .github/workflows/*.yml

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
