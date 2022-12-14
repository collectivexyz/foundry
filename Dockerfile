FROM debian:stable-slim as go-builder
# defined from build kit
# DOCKER_BUILDKIT=1 docker build . -t ...
ARG TARGETARCH

RUN export DEBIAN_FRONTEND=noninteractive && \
  apt update && \
  apt install -y -q --no-install-recommends \
    git curl gnupg2 build-essential coreutils \
    openssl libssl-dev pkg-config \
    ca-certificates apt-transport-https \
  python3 && \
  apt clean && \
  rm -rf /var/lib/apt/lists/*

## Go Lang
ARG GO_VERSION=1.19.3
ADD https://go.dev/dl/go${GO_VERSION}.linux-$TARGETARCH.tar.gz /go-ethereum/go${GO_VERSION}.linux-$TARGETARCH.tar.gz
# RUN cat /go-ethereum/go${GO_VERSION}.linux-$TARGETARCH.tar.gz | sha256sum -c go.${TARGETARCH}.sha256
RUN tar -C /usr/local -xzf /go-ethereum/go${GO_VERSION}.linux-$TARGETARCH.tar.gz
ENV PATH=$PATH:/usr/local/go/bin
RUN go version

## Go Ethereum
WORKDIR /go-ethereum
ARG ETH_VERSION=1.10.26
ADD https://github.com/ethereum/go-ethereum/archive/refs/tags/v${ETH_VERSION}.tar.gz /go-ethereum/go-ethereum-${ETH_VERSION}.tar.gz
RUN tar -zxf go-ethereum-${ETH_VERSION}.tar.gz  -C /go-ethereum
WORKDIR /go-ethereum/go-ethereum-${ETH_VERSION}
RUN go mod download 
RUN go run build/ci.go install

FROM debian:stable-slim as foundry-builder
# defined from build kit
# DOCKER_BUILDKIT=1 docker build . -t ...
ARG TARGETARCH

RUN export DEBIAN_FRONTEND=noninteractive && \
  apt update && \
  apt install -y -q --no-install-recommends \
    git curl gnupg2 build-essential linux-headers-${TARGETARCH} \
    g++-10 libc6-dev \ 
    openssl libssl-dev pkg-config \
    ca-certificates apt-transport-https \
  python3 && \
  apt clean && \
  rm -rf /var/lib/apt/lists/*

RUN useradd --create-home -s /bin/bash mr
RUN usermod -a -G sudo mr
RUN echo '%mr ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers


WORKDIR /rustup
## Rust
ADD https://sh.rustup.rs /rustup/rustup.sh
RUN chmod 755 /rustup/rustup.sh

ENV USER=mr
USER mr
RUN /rustup/rustup.sh -y --default-toolchain stable --profile minimal

## Foundry
WORKDIR /build

# latest https://github.com/foundry-rs/foundry
ENV PATH=$PATH:~mr/.cargo/bin
RUN git clone https://github.com/foundry-rs/foundry

WORKDIR /build/foundry
RUN [[ "$TARGETARCH" = "arm64" ]] && export CFLAGS=-mno-outline-atomics || true && \
    . $HOME/.cargo/env && \
    cargo build --release && \
    strip target/release/forge && \
    strip target/release/cast && \
    strip target/release/anvil

#    cargo install --path ./cli --profile release --bins --locked --force

FROM debian:stable-slim
ARG TARGETARCH

RUN export DEBIAN_FRONTEND=noninteractive && \
  apt update && \
  apt install -y -q --no-install-recommends \
    git gnupg2 curl build-essential \
    libz3-dev z3 \
    ca-certificates apt-transport-https \
    sudo ripgrep npm procps \
    python3 python3-pip python3-dev && \
  apt clean && \
  rm -rf /var/lib/apt/lists/*

RUN npm install yarn -g

RUN useradd --create-home -s /bin/bash mr
RUN usermod -a -G sudo mr
RUN echo '%mr ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# SOLC
COPY --from=ghcr.io/jac18281828/solc:latest /usr/local/bin/solc /usr/local/bin
COPY --from=ghcr.io/jac18281828/solc:latest /usr/local/bin/yul-phaser /usr/local/bin
COPY --from=ghcr.io/jac18281828/solc:latest /usr/local/bin/solidity-upgrade /usr/local/bin
RUN solc --version

## Rust 
COPY --chown=mr:mr --from=foundry-builder /home/mr/.cargo /home/mr/.cargo

# GO LANG
COPY --from=go-builder /usr/local/go /usr/local/go

## GO Ethereum Binaries
ARG ETH_VERSION=1.10.26
COPY --from=go-builder /go-ethereum/go-ethereum-${ETH_VERSION}/build/bin /usr/local/bin

# Foundry
COPY --from=foundry-builder /build/foundry/target/release/forge /usr/local/bin/forge
COPY --from=foundry-builder /build/foundry/target/release/cast /usr/local/bin/cast
COPY --from=foundry-builder /build/foundry/target/release/anvil /usr/local/bin/anvil

LABEL org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.name="foundry" \
    org.label-schema.description="Foundry RS Development Container" \
    org.label-schema.url="https://github.com/collectivexyz/foundry" \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url="git@github.com:collectivexyz/foundry.git" \
    org.label-schema.vendor="collectivexyz" \
    org.label-schema.version=$VERSION \
    org.label-schema.schema-version="1.0"

