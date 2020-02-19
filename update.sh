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
register_current_version

# Alpine Linux
update_image "alpine" "Alpine" "x86_64" "(\d+\.)+\d+"

# Minecraft Server
NEW_MC_VERSION=$(curl -s -L "https://launchermeta.mojang.com/mc/game/version_manifest.json" | jq -r ".latest.release")
CURRENT_MC_VERSION="${_CURRENT_VERSION%-*}"
if [ "$CURRENT_MC_VERSION" != "$NEW_MC_VERSION" ]; then
	prepare_update "mcserver" "MC Server" "$CURRENT_MC_VERSION" "$NEW_MC_VERSION"
	update_version "$NEW_MC_VERSION"

	METADATA_URL=$(curl -s -L "https://launchermeta.mojang.com/mc/game/version_manifest.json" | jq -r ".versions[] | select(.id==\"$NEW_MC_VERSION\") | .url")
	DOWNLOAD_URL=$(curl -s -L "$METADATA_URL" | jq -r ".downloads.server.url")
	
	# Since the minecraft server is downloaded by a url, the version number needs to be replaced 
	_UPDATES[-3]="BIN_URL"
	_UPDATES[-2]="\".*\""
	_UPDATES[-1]="\"$DOWNLOAD_URL\""
fi

# OpenJDK-JRE
update_alpine_pkg "openjdk11-jre-headless" "OpenJRE" "false" "community" "(\d+\.)+\d+_p\d+-r\d+"

if ! updates_available; then
	echo "No updates available."
	exit 0
fi

# Perform modifications
if [ "${1+}" = "--noconfirm" ] || confirm_action "Save changes?"; then
	save_changes

	if [ "${1+}" = "--noconfirm" ] || confirm_action "Commit changes?"; then
		commit_changes
	fi
fi
