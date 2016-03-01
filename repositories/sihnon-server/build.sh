#!/bin/bash
set -e

. /vagrant/scripts/repositories.sh

export DOCKER_PULL_IMAGE="${DOCKER_PULL_IMAGE:-1}"
export REPOSITORY_DESCRIPTION="Sihnon server packages"

BUILD_ARGS=(
    "app-admin/puppetdb"
    "app-admin/puppetserver"
    "app-backup/backuppc"
    "dev-db/phppgadmin"
    "dev-db/phpmyadmin"
    "www-apps/cgit"
    "www-apps/dokuwiki"
    "www-apps/gitlabhq"
    "www-apps/piwik"
    "www-apps/wordpress"
    "www-servers/gitlab-workhorse"
    "--layman awesome"
    "--layman gitlab"
)

build_all "${BUILD_ARGS[@]}"
