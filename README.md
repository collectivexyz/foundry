# Foundry Development Container for Docker and VS Code

This development container for Visual Studio Code is a pre-configured and isolated environment that allows you to develop, build, and test your software projects using consistent tools and settings.   This development container can be used in Docker to create a standardized and reproducible environment for your development workflow. This is useful when working on projects that require specific versions of programming languages, libraries, tools, and other dependencies. By using this development container, you can ensure that all members of your development team work with the same development environment, reducing issues related to differences in configurations and dependencies.

Key benefits of using development containers in Visual Studio Code include:

1. **Consistency**: Development containers ensure that everyone on the team is using the same environment, reducing "works on my machine" issues.

2. **Isolation**: Containers provide isolation from the host system, preventing conflicts between different software versions.

3. **Reproducibility**: Containers can be versioned, making it easy to replicate the exact development environment in different stages of the project.

4. **Portability**: Development containers can be shared and run on different machines, making it easier to onboard new team members or work across multiple devices.

5. **Dependency Management**: Containers encapsulate dependencies, eliminating the need to install and manage them directly on the host system.

To use this development container in Visual Studio Code, specify the `Dockerfile` as defined below and reopen in the Remote Containers module.

# Supported Toolchain

Everything needed to develop smart contracts with Ethereum and [Foundry](https://github.com/foundry-rs/foundry)

GO: 1.26
ETH: 1.17.3
SOLC: 0.8.30
NODE: 22.22.3

#### Deployments 

[Releases](https://github.com/collectivexyz/foundry/pkgs/container/foundry)

### Building

* requires:
  - 16 Gb memory
  - Docker  
  - BuildKit TARGETARCH
   `$ DOCKER_BUILDKIT=1 docker build . -t ... `


## arm64

  Multi-arch images (`linux/amd64` and `linux/arm64`) are published to the ghcr registry, so the container runs natively on Apple silicon.

  To build locally instead, run:
  ` $ sh build.sh `

  Then it can be used normally, as below.

## Example Dockerfile

```
FROM ghcr.io/collectivexyz/foundry:latest

RUN forge build --sizes

CMD ["forge", "test", "-vvv"]
```

### Architecture
* linux/amd64
* linux/arm64
