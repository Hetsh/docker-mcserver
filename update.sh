#!/usr/bin/env bash


# Abort on any error
set -e -u

# Simpler git usage, relative file paths
CWD=$(dirname "$0")
cd "$CWD"

# Load helpful functions
source libs/common.sh
source libs/docker.sh

# Check dependencies
assert_dependency "jq"
assert_dependency "curl"

# Alpine Linux
update_image "amd64/alpine" "Alpine Linux" "false" "\d{8}"

# Minecraft Server
NAME="MC Server"
CURRENT_MC_VERSION="${_CURRENT_VERSION%-*}"
NEW_MC_VERSION=$(curl --silent --location "https://launchermeta.mojang.com/mc/game/version_manifest.json" | jq -r ".latest.release")
if [ -z "$CURRENT_MC_VERSION" ] || [ -z "$NEW_MC_VERSION" ]; then
	echo -e "\e[31mFailed to get $NAME version!\e[0m"
elif [ "$CURRENT_MC_VERSION" != "$NEW_MC_VERSION" ]; then
	METADATA_URL=$(curl --silent --location "https://launchermeta.mojang.com/mc/game/version_manifest.json" | jq -r ".versions[] | select(.id==\"$NEW_MC_VERSION\") | .url")
	DOWNLOAD_URL=$(curl --silent --location "$METADATA_URL" | jq -r ".downloads.server.url")
	if [ -z "$DOWNLOAD_URL" ]; then
		echo -e "\e[31mFailed to get $NAME download url!\e[0m"
	else
		prepare_update "BIN_URL" "$NAME" "$CURRENT_MC_VERSION" "$NEW_MC_VERSION" "\".*\"" "\"$DOWNLOAD_URL\""
		update_version "$NEW_MC_VERSION"
	fi
fi

# OpenJRE
update_pkg "openjdk17-jre-headless" "Headless JRE" "false" "https://pkgs.alpinelinux.org/package/edge/community/x86_64" "(\d+\.)+\d+_p\d+-r\d+"

if ! updates_available; then
	#echo "No updates available."
	exit 0
fi

# Perform modifications
if [ "${1-}" = "--noconfirm" ] || confirm_action "Save changes?"; then
	save_changes

	if [ "${1-}" = "--noconfirm" ] || confirm_action "Commit changes?"; then
		commit_changes
	fi
fi
