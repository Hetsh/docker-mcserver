#!/usr/bin/env bash


# Abort on any error
set -e -u -o pipefail

# Simpler git usage, relative file paths
CWD=$(dirname "$0")
cd "$CWD"

# Load helpful functions
source libs/common.sh
source libs/docker.sh

# Check dependencies
assert_dependency "jq"
assert_dependency "curl"

# Updates
update_image "amd64/alpine" "\d{8}" "Alpine Linux"
update_packages_apk "hetsh/mcserver"
URL_ID="BIN_URL"
CURRENT_DOWNLOAD_URL=$(grep --only-matching --perl-regexp "(?<=$URL_ID=\")[^\"]+" "Dockerfile")
NEW_MC_VERSION=$(curl_request "https://launchermeta.mojang.com/mc/game/version_manifest.json" | jq -r ".latest.release")
METADATA_URL=$(curl_request "https://launchermeta.mojang.com/mc/game/version_manifest.json" | jq -r ".versions[] | select(.id==\"$NEW_MC_VERSION\") | .url")
NEW_DOWNLOAD_URL=$(curl_request "$METADATA_URL" | jq -r ".downloads.server.url")
process_update "$URL_ID" "\"$CURRENT_DOWNLOAD_URL\"" "\"$NEW_DOWNLOAD_URL\"" "MC Server" "${_GIT_VERSION%-*}" "$NEW_MC_VERSION"
if ! updates_available; then
	echo "No updates available."
	exit 0
fi

# Perform modifications
if test "${1-}" == "--noconfirm" || confirm_action "Save changes?"; then
	save_changes

	if test "${1-}" == "--noconfirm" || confirm_action "Commit changes?"; then
		commit_changes "BIN_URL"
	fi
fi
