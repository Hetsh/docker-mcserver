#!/usr/bin/env bash

set -e
trap "exit" SIGINT

if ! [ -x "$(command -v jq)" ]
then
    echo "JSON Parser \"jq\" is required but not installed!"
    exit 1
fi

if ! [ -x "$(command -v curl)" ]
then
    echo "\"curl\" is required but not installed!"
    exit 2
fi

if ! docker version &> /dev/null
then
    echo "Docker daemon is not running or you have unsufficient permissions!"
    exit 3
fi

read -e -i "hetsh" -p "Enter DockerHub username: " HUB_USER
read -s -p "Enter password: " HUB_PASSWORD && echo ""

LATEST_VERSION=$(curl -s -L "https://launchermeta.mojang.com/mc/game/version_manifest.json" | jq -r ".latest.release")
METADATA_URL=$(curl -s -L "https://launchermeta.mojang.com/mc/game/version_manifest.json" | jq -r ".versions[] | select(.id==\"$LATEST_VERSION\") | .url")
DOWNLOAD_URL=$(curl -s -L "$METADATA_URL" | jq -r ".downloads.server.url")

BUILD_DIR=$(mktemp -d /tmp/docker-build-XXXXXXXXXX)
trap "rm -rf $BUILD_DIR" EXIT
cd "$BUILD_DIR"

USER_NAME=mcs
SERVER_JAR=/server.jar
echo "FROM alpine:3.10.3
RUN apk add --no-cache openjdk11-jre-headless
RUN adduser -D -u 1357 $USER_NAME
ADD --chown=$USER_NAME:$USER_NAME \"$DOWNLOAD_URL\" \"$SERVER_JAR\"
USER mcs
WORKDIR /mcserver
VOLUME [/mcserver]
EXPOSE 25565
ENTRYPOINT [\"java\", \"-jar\", \"$SERVER_JAR\", \"nogui\"]" > Dockerfile
docker build --compress --tag "hetsh/mcserver:$LATEST_VERSION" .

echo -e "$HUB_PASSWORD" | docker login --username "$HUB_USER" --password-stdin
trap "docker logout" EXIT
docker push "hetsh/mcserver:$LATEST_VERSION"