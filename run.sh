#!/usr/bin/env bash

VERSION=$(git rev-parse HEAD | cut -c 1-8)

PROJECT=collectivexyz/foundry

PLATFORM=linux/amd64

DOCKER_BUILDKIT=1 docker build --platform ${PLATFORM} . -t ${PROJECT}:${VERSION} && \
	docker run --rm -i -t ${PROJECT}:${VERSION}
