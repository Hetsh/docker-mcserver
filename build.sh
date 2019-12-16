#!/usr/bin/env bash

set -e
trap "exit" SIGINT

if ! docker version &> /dev/null
then
    echo "Docker daemon is not running or you have unsufficient permissions!"
    exit 1
fi

APP_UID=1357
APP_NAME="mcserver"
docker build --tag "$APP_NAME" .

read -p "Test image? [y/n]" -n 1 -r && echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
	TMP_DIR=$(mktemp -d /tmp/mcserver-XXXXXXXXXX)
	trap "rm -rf $TMP_DIR" EXIT
	echo "eula=true" > "$TMP_DIR/eula.txt"
	chown -R "$APP_UID":"$APP_UID" "$TMP_DIR"

	docker run \
	--rm \
	--interactive \
	--publish 25565:25565 \
	--mount type=bind,source="$TMP_DIR",target="/$APP_NAME" \
	"$APP_NAME"
fi