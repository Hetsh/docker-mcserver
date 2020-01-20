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

# Base Image
IMAGE_NAME="alpine"
CURRENT_IMAGE_VERSION=$(cat Dockerfile | grep "FROM $IMAGE_NAME:")
CURRENT_IMAGE_VERSION="${CURRENT_IMAGE_VERSION#*:}"
IMAGE_VERSION=$(curl -L -s "https://registry.hub.docker.com/v2/repositories/library/$IMAGE_NAME/tags" | jq '."results"[]["name"]' | grep -m 1 -P -o "(\d+\.)+\d+" )
if [ "$CURRENT_IMAGE_VERSION" != "$IMAGE_VERSION" ]
then
	echo "Alpine $IMAGE_VERSION available!"

	RELEASE="${CURRENT_VERSION#*-}"
	NEXT_VERSION="${CURRENT_VERSION%-*}-$((RELEASE+1))"
fi

# Application
CURRENT_APP_VERSION=${CURRENT_VERSION%-*}
APP_VERSION=$(curl -s -L "https://launchermeta.mojang.com/mc/game/version_manifest.json" | jq -r ".latest.release")
if [ "$CURRENT_APP_VERSION" != "$APP_VERSION" ]
then
	echo "MC Server $APP_VERSION available!"

	METADATA_URL=$(curl -s -L "https://launchermeta.mojang.com/mc/game/version_manifest.json" | jq -r ".versions[] | select(.id==\"$APP_VERSION\") | .url")
	DOWNLOAD_URL=$(curl -s -L "$METADATA_URL" | jq -r ".downloads.server.url")

	NEXT_VERSION="$APP_VERSION-1"
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
			sed -i "s|FROM $IMAGE_NAME:.*|FROM $IMAGE_NAME:$IMAGE_VERSION|" Dockerfile
			CHANGELOG+="Alpine $CURRENT_IMAGE_VERSION -> $IMAGE_VERSION, "
		fi
		
		if [ "$CURRENT_APP_VERSION" != "$APP_VERSION" ]
		then
			sed -i "s|ARG BIN_URL=\".*\"|ARG BIN_URL=\"$DOWNLOAD_URL\"|" Dockerfile
			CHANGELOG+="MC Server $CURRENT_APP_VERSION -> $APP_VERSION, "
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
