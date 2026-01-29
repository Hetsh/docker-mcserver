#!/bin/bash
# shellcheck disable=SC2034

# This file will be sourced by scripts/update.sh to customize the update process


MAIN_ITEM="BIN_URL"
GIT_VERSION="$(git describe --tags --first-parent --abbrev=0)"
update_image "amd64/alpine" "\\d{8}" "Alpine Linux"
update_packages_apk "hetsh/mcserver"

URL_ID="BIN_URL"
CURRENT_DOWNLOAD_URL=$(grep --only-matching --perl-regexp "(?<=$URL_ID=\")[^\"]+" "Dockerfile")
NEW_MC_VERSION=$(curl_request "https://launchermeta.mojang.com/mc/game/version_manifest.json" | jq -r ".latest.release")
METADATA_URL=$(curl_request "https://launchermeta.mojang.com/mc/game/version_manifest.json" | jq -r ".versions[] | select(.id==\"$NEW_MC_VERSION\") | .url")
NEW_DOWNLOAD_URL=$(curl_request "$METADATA_URL" | jq -r ".downloads.server.url")
process_update "$URL_ID" "\"$CURRENT_DOWNLOAD_URL\"" "\"$NEW_DOWNLOAD_URL\"" "MC Server" "${GIT_VERSION%-*}" "$NEW_MC_VERSION"
