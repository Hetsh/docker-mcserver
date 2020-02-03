#!/usr/bin/env bash


# Use traps for cleanup steps
add_cleanup() {
	_CLEANUP_TRAPS="$1 && ${_CLEANUP_TRAPS+}"
	trap "echo -n 'Cleaning up... '; $_CLEANUP_TRAPS echo 'done!' || echo 'failed!'" EXIT
}

# Ensure depending programs exist
assert_dependency() {
	if ! [ -x "$(command -v $1)" ]; then
		echo "\"$1\" is required but not installed!"
		exit -1
	fi
}

# Import current version
register_current_version() {
	_CURRENT_VERSION="$1"
	_NEXT_VERSION="$_CURRENT_VERSION"
}

# Set version number, indicating major application update
update_version() {
	_NEXT_VERSION="$1-1"
}

# Increase release counter, indicating a minor package update
update_release() {
	# Prevent overriding major update changes
	if ! updates_available; then
		_CURRENT_RELEASE="${_CURRENT_VERSION#*-}"
		_NEXT_VERSION="${_CURRENT_VERSION%-*}-$((_CURRENT_RELEASE+1))"
	fi
}

# Check for available updates
updates_available() {
	if [ "$_CURRENT_VERSION" = "$_NEXT_VERSION" ]; then
		return 1
	else
		return 0
	fi
}

# Ask user if action should be performed
confirm_action() {
	read -p "$1 [y/n]" -n 1 -r && echo
	if [ "$REPLY" = "y" ]; then
		return 0
	else
		return 1
	fi
}

# Push changes to git
commit_changes() {
	git add Dockerfile
	git commit -m "$1"
	git push
	git tag "$_NEXT_VERSION"
	git push origin "$_NEXT_VERSION"
}