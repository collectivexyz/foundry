FROM debian:stable-slim as builder

RUN export DEBIAN_FRONTEND=noninteractive && \
  apt update && \
  apt install -y -q --no-install-recommends \
  git curl gnupg2 build-essential openssl libssl-dev pkg-config \
  ca-certificates apt-transport-https \
  python3 && \
  apt clean && \
  rm -rf /var/lib/apt/lists/*

RUN useradd --create-home -s /bin/bash mr
RUN usermod -a -G sudo mr
RUN echo '%mr ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

## Go Lang
ARG GO_VERSION=1.18.5
ARG PROCESSOR_ARCH=amd64
ADD https://go.dev/dl/go${GO_VERSION}.linux-${PROCESSOR_ARCH}.tar.gz /go-ethereum/go${GO_VERSION}.linux-${PROCESSOR_ARCH}.tar.gz
RUN tar -C /usr/local -xzf /go-ethereum/go${GO_VERSION}.linux-${PROCESSOR_ARCH}.tar.gz
ENV PATH=$PATH:/usr/local/go/bin
RUN go version

## Go Ethereum
WORKDIR /go-ethereum
ARG ETH_VERSION=1.10.25
ADD https://github.com/ethereum/go-ethereum/archive/refs/tags/v${ETH_VERSION}.tar.gz /go-ethereum/${ETH_VERSION}.tar.gz
RUN tar -zxf ${ETH_VERSION}.tar.gz  -C /go-ethereum
WORKDIR /go-ethereum/go-ethereum-${ETH_VERSION}
RUN go mod download 
RUN go run build/ci.go install

## Rust
ADD https://sh.rustup.rs /rustup/rustup-init.sh
RUN chmod 755 /rustup/rustup-init.sh 

WORKDIR /rustup
ENV USER=mr
USER mr
RUN /rustup/rustup-init.sh -y --default-toolchain stable --profile minimal
RUN ~mr/.cargo/bin/rustup default stable


## Foundry
WORKDIR /foundry

# latest https://github.com/foundry-rs/foundry
RUN ~mr/.cargo/bin/cargo install --git https://github.com/foundry-rs/foundry --profile local --locked foundry-cli

FROM debian:stable-slim

RUN export DEBIAN_FRONTEND=noninteractive && \
  apt update && \
  apt install -y -q --no-install-recommends \
  git gnupg2 curl build-essential \
  sudo ripgrep npm procps \
  ca-certificates apt-transport-https \
  python3 python3-pip && \
  apt clean && \
  rm -rf /var/lib/apt/lists/*


# RUN npm install npm -g
RUN npm install yarn -g

RUN useradd --create-home -s /bin/bash mr
RUN usermod -a -G sudo mr
RUN echo '%mr ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# SOLC Docs
RUN pip install --upgrade pip
RUN pip install solc-select
RUN solc-select install 0.8.17

ENV SOLC_VERSION=0.8.17
RUN solc --version

# GO LANG
COPY --from=builder /usr/local/go /usr/local/go

## GO Ethereum Binaries
ARG ETH_VERSION=1.10.25
COPY --from=builder /go-ethereum/go-ethereum-${ETH_VERSION}/build/bin /usr/local/bin
COPY --chown=mr:mr --from=builder /home/mr/.cargo /home/mr/.cargo
