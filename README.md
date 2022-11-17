# Foundry Development Container

Everything needed to develop smart contracts with Ethereum and [Foundry](https://github.com/foundry-rs/foundry)

GO: 1.19.3
ETH: 1.10.26
SOLC: 0.8.17

### Building

Build requires BuildKit TARGETARCH

`$ DOCKER_BUILDKIT=1 docker build . -t ... `

### Architecture
* linux/amd64 
* linux/arm64


## Example Dockerfile

```
FROM ghcr.io/collectivexyz/foundry:latest

ENV PATH=${PATH}:~/.cargo/bin
RUN ~mr/.cargo/bin/forge build --sizes

CMD ~mr/.cargo/bin/forge test -vvv
```
