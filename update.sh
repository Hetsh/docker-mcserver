#!/usr/bin/env bash


# Abort on any error
set -eu

# Simpler git usage, relative file paths
CWD=$(dirname "$0")
cd "$CWD"

# Load helpful functions
source libs/common.sh
source libs/docker.sh

# Check dependencies
assert_dependency "jq"
assert_dependency "curl"

# Current version of docker image
CURRENT_VERSION=$(git describe --tags --abbrev=0)
register_current_version "$CURRENT_VERSION"

# Alpine Linux
IMAGE_PKG="alpine"
IMAGE_NAME="Alpine"
IMAGE_REGEX="(\d+\.)+\d+"
IMAGE_TAGS=$(curl -L -s "https://registry.hub.docker.com/v2/repositories/library/$IMAGE_PKG/tags" | jq '."results"[]["name"]' | grep -P -o "$IMAGE_REGEX")
IMAGE_VERSION=$(echo "$IMAGE_TAGS" | sort --version-sort | tail -n 1)
CURRENT_IMAGE_VERSION=$(cat "Dockerfile" | grep -P -o "FROM $IMAGE_PKG:\K$IMAGE_REGEX")
if [ "$CURRENT_IMAGE_VERSION" != "$IMAGE_VERSION" ]; then
	echo "$IMAGE_NAME $IMAGE_VERSION available!"
	update_release
fi

# OpenJDK-JRE
JRE_PKG="openjdk11-jre-headless"
JRE_NAME="OpenJRE"
JRE_REGEX="(\d+\.)+\d+_p\d+-r\d+"
JRE_VERSION=$(curl -L -s "https://pkgs.alpinelinux.org/package/v${IMAGE_VERSION%.*}/community/x86_64/$JRE_PKG" | grep -m 1 -P -o "$JRE_REGEX")
CURRENT_JRE_VERSION=$(cat "Dockerfile" | grep -P -o "$JRE_PKG=\K$JRE_REGEX")
if [ "$CURRENT_JRE_VERSION" != "$JRE_VERSION" ]; then
	echo "$JRE_NAME $JRE_VERSION available!"
	update_release
fi

# Minecraft Server
MC_NAME="MC Server"
MC_VERSION=$(curl -s -L "https://launchermeta.mojang.com/mc/game/version_manifest.json" | jq -r ".latest.release")
CURRENT_MC_VERSION=${CURRENT_VERSION%-*}
if [ "$CURRENT_MC_VERSION" != "$MC_VERSION" ]; then
	echo "$MC_NAME $MC_VERSION available!"
	update_version "$MC_VERSION"

	METADATA_URL=$(curl -s -L "https://launchermeta.mojang.com/mc/game/version_manifest.json" | jq -r ".versions[] | select(.id==\"$MC_VERSION\") | .url")
	DOWNLOAD_URL=$(curl -s -L "$METADATA_URL" | jq -r ".downloads.server.url")
fi

if ! updates_available; then
	echo "No updates available."
	exit 0
fi

# Perform modifications
if [ "${1+}" = "--noconfirm" ] || confirm_action "Save changes?"; then
	if [ "$CURRENT_IMAGE_VERSION" != "$IMAGE_VERSION" ]; then
		sed -i "s|FROM $IMAGE_PKG:$IMAGE_REGEX|FROM $IMAGE_PKG:$IMAGE_VERSION|" Dockerfile
		CHANGELOG+="$IMAGE_NAME $CURRENT_IMAGE_VERSION -> $IMAGE_VERSION, "
	fi
	if [ "$CURRENT_JRE_VERSION" != "$JRE_VERSION" ]; then
		sed -i "s|$JRE_PKG=$JRE_REGEX|$JRE_PKG=$JRE_VERSION|" Dockerfile
		CHANGELOG+="$JRE_NAME $CURRENT_JRE_VERSION -> $JRE_VERSION, "
	fi
	if [ "$CURRENT_MC_VERSION" != "$MC_VERSION" ]; then
		sed -i "s|BIN_URL=\".*\"|BIN_URL=\"$DOWNLOAD_URL\"|" Dockerfile
		CHANGELOG+="$MC_NAME $CURRENT_MC_VERSION -> $MC_VERSION, "
	fi
	CHANGELOG="${CHANGELOG%,*}"

	if [ "${1+}" = "--noconfirm" ] || confirm_action "Commit changes?"; then
		commit_changes "$CHANGELOG"
	fi
fi
