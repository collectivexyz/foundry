# Foundry Development Container

Everything needed to develop smart contracts with Ethereum and [Foundry](https://github.com/foundry-rs/foundry)

GO: 1.20.6
ETH: 1.11.6
SOLC: 0.8.20

#### Deployments 

[Releases](https://github.com/collectivexyz/foundry/pkgs/container/foundry)

### Building

* requires:
  - 16 Gb memory
  - Docker  
  - BuildKit TARGETARCH
   `$ DOCKER_BUILDKIT=1 docker build . -t ... `


## arm64

  It's possible to use this container on Apple Silicon but an image is not provided in the ghcr registry at this time.

  To build locally, run:
  ` $ sh build.sh `

  Then it can be used normally, as below.

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
