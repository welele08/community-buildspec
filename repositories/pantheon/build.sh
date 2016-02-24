#!/bin/bash
set -e

. /vagrant/scripts/repositories.sh

# Build Pantheon repository
DOCKER_PULL_IMAGE=1 OUTPUT_DIR="/vagrant/artifacts/pantheon-binhost"  sabayon-buildpackages pantheon-base/pantheon-shell \
                                                                                            --layman elementary \
                                                                                            --equo x11-libs/gtk+:3

# Create repository
DOCKER_PULL_IMAGE=1 REPOSITORY_NAME="pantheon" REPOSITORY_DESCRIPTION="Pantheon Desktop Environment Community Repository" PORTAGE_ARTIFACTS="/vagrant/artifacts/pantheon-binhost" OUTPUT_DIR="/vagrant/artifacts/pantheon" sabayon-createrepo

# Deploy repository "pantheon" inside "repositories"
#deploy_all "pantheon"
