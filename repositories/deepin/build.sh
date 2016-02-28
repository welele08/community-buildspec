#!/bin/bash
set -e

. /vagrant/scripts/repositories.sh

export DOCKER_PULL_IMAGE="${DOCKER_PULL_IMAGE:-1}"
export EMERGE_DEFAULTS_ARGS="-k --accept-properties=-interactive --verbose --oneshot --complete-graph --buildpkg"
export REPOSITORY_DESCRIPTION="Deeping Desktop Environment Community Repository"

BUILD_ARGS=(
  "dde-base/dde-meta"
  "--layman gentoo-zh"
)

build_all "${BUILD_ARGS[@]}"
