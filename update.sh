#!/usr/bin/env bash

set -e
trap "exit" SIGINT

if [ "$USER" == "root" ]
then
	echo "Must not be executed as user \"root\"!"
	exit -1
fi

if ! [ -x "$(command -v jq)" ]
then
	echo "JSON Parser \"jq\" is required but not installed!"
	exit -2
fi

if ! [ -x "$(command -v curl)" ]
then
	echo "\"curl\" is required but not installed!"
	exit -3
fi

WORK_DIR="${0%/*}"
cd "$WORK_DIR"

CURRENT_VERSION=$(git describe --tags --abbrev=0)
NEXT_VERSION="$CURRENT_VERSION"

# Aline Linux
IMAGE_PKG="alpine"
IMAGE_NAME="Alpine"
IMAGE_REGEX="(\d+\.)+\d+"
IMAGE_VERSION=$(curl -L -s "https://registry.hub.docker.com/v2/repositories/library/$IMAGE_PKG/tags" | jq '."results"[]["name"]' | grep -m 1 -P -o "$IMAGE_REGEX" )
CURRENT_IMAGE_VERSION=$(cat Dockerfile | grep -P -o "FROM $IMAGE_PKG:\K$IMAGE_REGEX")
if [ "$CURRENT_IMAGE_VERSION" != "$IMAGE_VERSION" ]
then
	echo "$IMAGE_NAME $IMAGE_VERSION available!"

	RELEASE="${CURRENT_VERSION#*-}"
	NEXT_VERSION="${CURRENT_VERSION%-*}-$((RELEASE+1))"
fi

# OpenJDK-JRE
JRE_PKG="openjdk11-jre-headless"
JRE_NAME="OpenJRE"
JRE_REGEX="(\d+\.)+\d+_p\d+-r\d+"
JRE_VERSION=$(curl -L -s "https://pkgs.alpinelinux.org/package/v${IMAGE_VERSION%.*}/community/x86_64/$JRE_PKG" | grep -m 1 -P -o "$JRE_REGEX")
CURRENT_JRE_VERSION=$(cat Dockerfile | grep -P -o "$JRE_PKG=\K$JRE_REGEX")
if [ "$CURRENT_JRE_VERSION" != "$JRE_VERSION" ]
then
	echo "$JRE_NAME $JRE_VERSION available!"

	RELEASE="${CURRENT_VERSION#*-}"
	NEXT_VERSION="${CURRENT_VERSION%-*}-$((RELEASE+1))"
fi

# Minecraft Server
MC_NAME="MC Server"
MC_VERSION=$(curl -s -L "https://launchermeta.mojang.com/mc/game/version_manifest.json" | jq -r ".latest.release")
CURRENT_MC_VERSION=${CURRENT_VERSION%-*}
if [ "$CURRENT_MC_VERSION" != "$MC_VERSION" ]
then
	echo "$MC_NAME $MC_VERSION available!"

	NEXT_VERSION="$MC_VERSION-1"

	METADATA_URL=$(curl -s -L "https://launchermeta.mojang.com/mc/game/version_manifest.json" | jq -r ".versions[] | select(.id==\"$MC_VERSION\") | .url")
	DOWNLOAD_URL=$(curl -s -L "$METADATA_URL" | jq -r ".downloads.server.url")
fi

if [ "$CURRENT_VERSION" == "$NEXT_VERSION" ]
then
	echo "No updates available."
else
	if [ "$1" == "--noconfirm" ]
	then
		SAVE="y"
	else
		read -p "Save changes? [y/n]" -n 1 -r SAVE && echo
	fi
	
	if [[ $SAVE =~ ^[Yy]$ ]]
	then
		if [ "$CURRENT_IMAGE_VERSION" != "$IMAGE_VERSION" ]
		then
			sed -i "s|FROM $IMAGE_PKG:$IMAGE_REGEX|FROM $IMAGE_PKG:$IMAGE_VERSION|" Dockerfile
			CHANGELOG+="$IMAGE_NAME $CURRENT_IMAGE_VERSION -> $IMAGE_VERSION, "
		fi
		
		if [ "$CURRENT_JRE_VERSION" != "$JRE_VERSION" ]
		then
			sed -i "s|$JRE_PKG=$JRE_REGEX|$JRE_PKG=$JRE_VERSION|" Dockerfile
			CHANGELOG+="$JRE_NAME $CURRENT_JRE_VERSION -> $JRE_VERSION, "
		fi
		
		if [ "$CURRENT_MC_VERSION" != "$MC_VERSION" ]
		then
			sed -i "s|BIN_URL=\".*\"|BIN_URL=\"$DOWNLOAD_URL\"|" Dockerfile
			CHANGELOG+="$MC_NAME $CURRENT_MC_VERSION -> $MC_VERSION, "
		fi

		CHANGELOG="${CHANGELOG%,*}"

		if [ "$1" == "--noconfirm" ]
		then
			COMMIT="y"
		else
			read -p "Commit changes? [y/n]" -n 1 -r COMMIT && echo
		fi

		if [[ $COMMIT =~ ^[Yy]$ ]]
		then
			git add Dockerfile
			git commit -m "$CHANGELOG"
			git push
			git tag "$NEXT_VERSION"
			git push origin "$NEXT_VERSION"
		fi
	fi
fi
