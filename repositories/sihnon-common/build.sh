#!/bin/bash
set -e

. /vagrant/scripts/repositories.sh

export DOCKER_PULL_IMAGE="${DOCKER_PULL_IMAGE:-1}"
export REPOSITORY_DESCRIPTION="Sihnon common packages"

BUILD_ARGS=(
      "net-misc/openssh"
)

build_all "${BUILD_ARGS[@]}"
