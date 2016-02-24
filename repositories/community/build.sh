#!/bin/bash
set -e

. /vagrant/scripts/repositories.sh

export DOCKER_PULL_IMAGE=1
export EMERGE_DEFAULTS_ARGS="-k --accept-properties=-interactive --verbose --oneshot --complete-graph --buildpkg"
export REPOSITORY_NAME="community"
export REPOSITORY_DESCRIPTION="Community Repository"

BUILD_ARGS=(
    "app-text/cherrytree"
    "app-misc/fluxgui"
    "--layman and3k-sunrise"
)

build_all "${BUILD_ARGS[@]}"
