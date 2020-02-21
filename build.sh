#!/usr/bin/env bash


# Abort on any error
set -e -u

# Simpler git usage, relative file paths
CWD=$(dirname "$0")
cd "$CWD"

# Load helpful functions
source libs/common.sh

# Check acces do docker daemon
assert_dependency "docker"
if ! docker version &> /dev/null; then
    echo "Docker daemon is not running or you have unsufficient permissions!"
    exit -1
fi

# Build the image
APP_NAME="mcserver"
docker build --tag "$APP_NAME" .

if confirm_action "Test image?"; then
	# Set up temporary directory
	TMP_DIR=$(mktemp -d "/tmp/$APP_NAME-XXXXXXXXXX")
	add_cleanup "rm -rf $TMP_DIR"
	echo "eula=true" > "$TMP_DIR/eula.txt"

	# Apply permissions, UID matches process user
	APP_UID=$(cat Dockerfile | grep -P -o "ARG APP_UID=\K\d+")
	chown -R "$APP_UID":"$APP_UID" "$TMP_DIR"

	# Start the test
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