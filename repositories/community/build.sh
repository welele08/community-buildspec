#!/bin/bash
set -e

. /vagrant/scripts/repositories.sh

# Build Pantheon repository
sabayon-buildpackages app-text/cherrytree \
                      media-sound/atraci-bin \
                      --layman and3k-sunrise \
                      --layman gentoo-el

# Create repository
REPOSITORY_NAME="community" REPOSITORY_DESCRIPTION="Community Repository"  sabayon-createrepo

# Deploy repository "pantheon" locally and remotely (if configured)
deploy_all "community"
