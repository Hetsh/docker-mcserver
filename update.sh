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

# Get url to new server version
LATEST_VERSION=$(curl -s -L "https://launchermeta.mojang.com/mc/game/version_manifest.json" | jq -r ".latest.release")
METADATA_URL=$(curl -s -L "https://launchermeta.mojang.com/mc/game/version_manifest.json" | jq -r ".versions[] | select(.id==\"$LATEST_VERSION\") | .url")
DOWNLOAD_URL=$(curl -s -L "$METADATA_URL" | jq -r ".downloads.server.url")
sed -i "s|ARG MC_URL=\".*\"|ARG MC_URL=\"$DOWNLOAD_URL\"|" Dockerfile

git add Dockerfile
git commit -m "Version bump to $LATEST_VERSION"
git push
git tag -f "$LATEST_VERSION"
git push -f origin "$LATEST_VERSION"