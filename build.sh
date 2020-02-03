#!/usr/bin/env bash

# Abort on any error
set -eu

# Traps for cleanup
add_cleanup() {
	CLEANUP_TRAPS="$1 && ${CLEANUP_TRAPS+}"
	trap "echo -n 'Cleaning up... '; $CLEANUP_TRAPS echo 'done!' || echo 'failed!'" EXIT
}


if ! docker version &> /dev/null
then
    echo "Docker daemon is not running or you have unsufficient permissions!"
    exit -1
fi

WORK_DIR="${0%/*}"
cd "$WORK_DIR"

APP_NAME="mcserver"
docker build --tag "$APP_NAME" .

read -p "Test image? [y/n]" -n 1 -r && echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
	TMP_DIR=$(mktemp -d "/tmp/$APP_NAME-XXXXXXXXXX")
	add_cleanup "rm -rf $TMP_DIR"
	echo "eula=true" > "$TMP_DIR/eula.txt"

	APP_UID=1357
	chown -R "$APP_UID":"$APP_UID" "$TMP_DIR"

	docker run \
	--rm \
	--interactive \
	--publish 25565:25565/tcp \
	--publish 25565:25565/udp \
	--publish 25575:25575/tcp \
	--mount type=bind,source="$TMP_DIR",target="/$APP_NAME" \
	--name "$APP_NAME" \
	"$APP_NAME"
fi