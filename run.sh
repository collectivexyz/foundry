#!/usr/bin/env bash

VERSION=$(git rev-parse HEAD | cut -c 1-8)

PROJECT=collectivexyz/foundry

DOCKER_BUILDKIT=1 docker build --progress plain . -t ${PROJECT}:${VERSION} && \
	docker run --rm -i -t ${PROJECT}:${VERSION}
