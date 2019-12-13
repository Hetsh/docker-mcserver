#!/usr/bin/env bash

set -e
trap "exit" SIGINT

if ! docker version &> /dev/null
then
    echo "Docker daemon is not running or you have unsufficient permissions!"
    exit 1
fi

TMP_DIR=$(mktemp -d /tmp/mcserver-XXXXXXXXXX)
trap "rm -rf $TMP_DIR" EXIT
echo "eula=true" > "$TMP_DIR/eula.txt"
chown -R 1357:1357 "$TMP_DIR"

IMAGE_NAME="mcserver"
docker build --tag "$IMAGE_NAME" .
docker run --rm --interactive --publish 25565:25565 --mount type=bind,source="$TMP_DIR",target=/mcserver "$IMAGE_NAME"