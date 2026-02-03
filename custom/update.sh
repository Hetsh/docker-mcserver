#!/bin/bash
# shellcheck disable=SC2034

# This file will be sourced by scripts/update.sh to customize the update process


GIT_VERSION="$(git describe --tags --first-parent --abbrev=0)"
MAIN_ITEM="BIN_URL"
function check_for_updates {
	update_base_image "\\d{8}-\\d+"
	update_packages "hetsh/mcserver"

	URL_ID="BIN_URL"
	CURRENT_DOWNLOAD_URL=$(grep --only-matching --perl-regexp "(?<=$URL_ID=\")[^\"]+" "Dockerfile")
	MC_MANIFEST=$(curl_request "https://launchermeta.mojang.com/mc/game/version_manifest.json")
	NEW_MC_VERSION=$(jq -r ".latest.release" <<< "$MC_MANIFEST")
	METADATA_URL=$(jq -r ".versions[] | select(.id==\"$NEW_MC_VERSION\") | .url" <<< "$MC_MANIFEST")
	NEW_DOWNLOAD_URL=$(curl_request "$METADATA_URL" | jq -r ".downloads.server.url")
	process_update "$URL_ID" "\"$CURRENT_DOWNLOAD_URL\"" "\"$NEW_DOWNLOAD_URL\"" "MC Server" "${GIT_VERSION%-*}" "$NEW_MC_VERSION"

}
