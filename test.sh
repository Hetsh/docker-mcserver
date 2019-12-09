#!/usr/bin/env bash

set -e
trap "exit" SIGINT

if ! docker version &> /dev/null
then
    echo "Docker daemon is not running or you have unsufficient permissions!"
    exit 1
fi

TMP_DIR=$(mktemp -d /tmp/docker-TMP-XXXXXXXXXX)
trap "rm -rf $TMP_DIR" EXIT
cp Dockerfile "$TMP_DIR"
echo "eula=true" > "$TMP_DIR/eula.txt"
chown -R 1357:1357 "$TMP_DIR"

cd "$TMP_DIR"
docker build --tag "mcserver" .
docker run --rm --interactive --name mcserver --publish 25565:25565 --mount type=bind,source="$TMP_DIR",target=/mcserver mcserver