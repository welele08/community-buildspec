#!/bin/bash

. /vagrant/scripts/repositories.sh

export REPOSITORY_DESCRIPTION="Sihnon server packages"

BUILD_ARGS=(
    "app-admin/puppetdb"
    "app-admin/puppetserver"
    "=app-backup/backuppc-3.3.0-r1"
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
