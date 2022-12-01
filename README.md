# Foundry Development Container

Everything needed to develop smart contracts with Ethereum and [Foundry](https://github.com/foundry-rs/foundry)

GO: 1.19.3
ETH: 1.10.26
SOLC: 0.8.17

### Building

* requires:
  - 16 Gb memory
  - docker  
  - BuildKit TARGETARCH
   `$ DOCKER_BUILDKIT=1 docker build . -t ... `


## arm64

  It's possible to use this container on Apple Silicon but a build is not provided in the ghcr registry at this time.

  To build locally, run:
  ` $ sh build.sh `

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
