#!/bin/bash
# shellcheck disable=SC2034

# This file will be sourced by scripts/build.sh to customize the build process


IMG_NAME="hetsh/mcserver"
function test_image {
	docker run \
		--rm \
		--interactive \
		--publish 25565:25565/tcp \
		--publish 25565:25565/udp \
		--publish 25575:25575/tcp \
		--volume /etc/localtime:/etc/localtime:ro \
		"$IMG_ID"
}
