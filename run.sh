#!/usr/bin/env bash

VERSION=$(git rev-parse HEAD | cut -c 1-10)

PROJECT=collectivexyz/foundry

docker build . -t ${PROJECT}:${VERSION} && \
	docker run --rm -i -t ${PROJECT}:${VERSION}
