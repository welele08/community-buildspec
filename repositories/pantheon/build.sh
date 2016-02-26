#!/bin/bash
set -e

. /vagrant/scripts/repositories.sh

export DOCKER_PULL_IMAGE="${DOCKER_PULL_IMAGE:-1}"
export EMERGE_DEFAULTS_ARGS="-k --accept-properties=-interactive --verbose --oneshot --complete-graph --buildpkg"
export REPOSITORY_NAME="pantheon"
export REPOSITORY_DESCRIPTION="Pantheon Desktop Environment Community Repository"

# Build Pantheon repository
OUTPUT_DIR="/vagrant/artifacts/pantheon-binhost" sabayon-buildpackages \
                                                                        pantheon-base/pantheon-shell \
                                                                        --layman elementary \
                                                                        --equo x11-libs/gtk+:3

# Creating our permanent binhost
cp -rf "/vagrant/artifacts/pantheon-binhost/*" $TEMPDIR

# Create repository
PORTAGE_ARTIFACTS="/vagrant/artifacts/pantheon-binhost" OUTPUT_DIR="/vagrant/artifacts/pantheon" sabayon-createrepo


rm -rf $TEMPDIR/*

# Deploy repository "pantheon" inside "repositories"
#deploy_all "pantheon"
