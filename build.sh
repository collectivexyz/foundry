#!/usr/bin/env bash

# install a local version of this image - useful on arm64 where there are currently no public
# distributions

VERSION=$(git rev-parse HEAD | cut -c 1-8)

PROJECT=collectivexyz/$(basename ${PWD})

# cross platform
# --platform=amd64
DOCKER_BUILDKIT=1 docker build --progress plain . -t ${PROJECT}:${VERSION} --build-arg VERSION=${VERSION} && \
    docker tag ${PROJECT}:${VERSION} ${PROJECT}:latest && \
    docker tag ${PROJECT}:${VERSION} ghcr.io/${PROJECT}:latest
