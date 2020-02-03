#!/usr/bin/env bash

# Abort on any error
set -eu

# Ensure depending programs exist
if ! [ -x "$(command -v jq)" ]; then
	echo "JSON parser \"jq\" is required but not installed!"
	exit -2
fi
if ! [ -x "$(command -v curl)" ]; then
	echo "\"cURL\" is required but not installed!"
	exit -3
fi

# Switch to project dir to use git
WORK_DIR="${0%/*}"
cd "$WORK_DIR"

# Current version of docker image
CURRENT_VERSION=$(git describe --tags --abbrev=0)
RELEASE="${CURRENT_VERSION#*-}"

# Check for available updates
NEXT_VERSION="$CURRENT_VERSION"
updates_available () {
	if [ "$CURRENT_VERSION" == "$NEXT_VERSION" ]; then
		return 1
	else
		return 0
	fi
}

# Increase release counter
update_release () {
	# Prevent overriding major update changes
	if ! updates_available; then
		NEXT_VERSION="${CURRENT_VERSION%-*}-$((RELEASE+1))"
	fi
}

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
	NEXT_VERSION="$MC_VERSION-1"

	METADATA_URL=$(curl -s -L "https://launchermeta.mojang.com/mc/game/version_manifest.json" | jq -r ".versions[] | select(.id==\"$MC_VERSION\") | .url")
	DOWNLOAD_URL=$(curl -s -L "$METADATA_URL" | jq -r ".downloads.server.url")
fi

if ! updates_available; then
	echo "No updates available."
	exit 0
fi

# Ask user if action should be performed
SKIP_CONFIRM="${1+}"
confirm_action () {
	if [ "$SKIP_CONFIRM" = "--noconfirm" ]; then
		return 0
	fi

	read -p "$1 [y/n]" -n 1 && echo
	if [ "$REPLY" = "y" ]; then
		return 0
	fi
	
	return 1
}

# Perform modifications
if confirm_action "Save changes?"; then
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

	if confirm_action "Commit changes?"; then
		git add Dockerfile
		git commit -m "$CHANGELOG"
		git push
		git tag "$NEXT_VERSION"
		git push origin "$NEXT_VERSION"
	fi
fi
