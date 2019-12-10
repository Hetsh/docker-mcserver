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

CURRENT_VERSION=$(git describe --tags)
CURRENT_VERSION=1.14.4-1
NEXT_VERSION="$CURRENT_VERSION"

# Alpine
CURRENT_ALPINE_VERSION=$(cat Dockerfile | grep "FROM alpine:")
CURRENT_ALPINE_VERSION="${CURRENT_ALPINE_VERSION#*:}"
ALPINE_VERSION=$(curl -L -s 'https://registry.hub.docker.com/v2/repositories/library/alpine/tags' | jq '."results"[]["name"]' | grep -P -o "(\d+\.)+\d+" | head -n 1)
if [ "$CURRENT_ALPINE_VERSION" != "$ALPINE_VERSION" ]
then
    #sed -i "s|FROM alpine:.*|FROM alpine:$ALPINE_VERSION|" Dockerfile
    RELEASE="${MC_VERSION#*-}"
    NEXT_VERSION="${CURRENT_VERSION%-*}-$((RELEASE+1))"

    echo "Updated Alpine to $ALPINE_VERSION"
fi

# MC Server
CURRENT_MC_VERSION=${CURRENT_VERSION%-*}
MC_VERSION=$(curl -s -L "https://launchermeta.mojang.com/mc/game/version_manifest.json" | jq -r ".latest.release")
if [ "$CURRENT_MC_VERSION" != "$MC_VERSION" ]
then
    METADATA_URL=$(curl -s -L "https://launchermeta.mojang.com/mc/game/version_manifest.json" | jq -r ".versions[] | select(.id==\"$MC_VERSION\") | .url")
    DOWNLOAD_URL=$(curl -s -L "$METADATA_URL" | jq -r ".downloads.server.url")

    #sed -i "s|ARG MC_URL=\".*\"|ARG MC_URL=\"$DOWNLOAD_URL\"|" Dockerfile
    BASE="${MC_VERSION%-*}"
    NEXT_VERSION="$MC_VERSION-1"

    echo "Updated MC Server to $MC_VERSION"
fi

if [ "$CURRENT_VERSION" == "$NEXT_VERSION" ]
then
    echo "Nothing changed."
else
    read -p "Commit changes?" -n 1 -r && echo
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        git add Dockerfile
        git commit -m "Version bump to $NEXT_VERSION"
        git push
        git tag -f "$NEXT_VERSION"
        git push -f origin "$NEXT_VERSION"
    fi
fi
