#!/bin/bash
set -e

. /vagrant/scripts/repositories.sh

export DOCKER_PULL_IMAGE="${DOCKER_PULL_IMAGE:-1}"
export REPOSITORY_DESCRIPTION="Sihnon server packages"

BUILD_ARGS=(
    "app-admin/puppetserver"
    "www-apps/wordpress"
)

build_all "${BUILD_ARGS[@]}"
