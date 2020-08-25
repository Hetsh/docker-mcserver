#!/usr/bin/env bash


# Abort on any error
set -e -u

# Simpler git usage, relative file paths
CWD=$(dirname "$0")
cd "$CWD"

# Load helpful functions
source libs/common.sh
source libs/docker.sh

# Check access to docker daemon
assert_dependency "docker"
if ! docker version &> /dev/null; then
	echo "Docker daemon is not running or you have unsufficient permissions!"
	exit -1
fi

# Build the image
APP_NAME="mcserver"
IMG_NAME="hetsh/$APP_NAME"
docker build --tag "$IMG_NAME" --tag "$IMG_NAME:$(git describe --tags --abbrev=0)" .

# Start the test
case "${1-}" in
	"--test")
		# Set up temporary directory
		TMP_DIR=$(mktemp -d "/tmp/$APP_NAME-XXXXXXXXXX")
		add_cleanup "rm -rf $TMP_DIR"
		echo "eula=true" > "$TMP_DIR/eula.txt"

		# Apply permissions, UID matches process user
		extract_var APP_UID "./Dockerfile" "\K\d+"
		chown -R "$APP_UID":"$APP_UID" "$TMP_DIR"

		# Start the test
		extract_var DATA_DIR "./Dockerfile" "\"\K[^\"]+"
		docker run \
		--rm \
		--tty \
		--interactive \
		--publish 25565:25565/tcp \
		--publish 25565:25565/udp \
		--publish 25575:25575/tcp \
		--mount type=bind,source="$TMP_DIR",target="$DATA_DIR" \
		--mount type=bind,source=/etc/localtime,target=/etc/localtime,readonly \
		--name "$APP_NAME" \
		"$IMG_NAME"
	;;
	"--upload")
		if ! tag_exists "$IMG_NAME"; then
			docker push "$IMG_NAME"
		fi
	;;
esac