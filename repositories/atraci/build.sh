#!/bin/bash
set -e

. /vagrant/scripts/repositories.sh

# Build Pantheon repository
sabayon-buildpackages media-sound/atraci-bin --layman gentoo-el

# Create repository
REPOSITORY_NAME="atraci" REPOSITORY_DESCRIPTION="Atraci Music Player Community Repository" sabayon-createrepo

# Deploy repository "atraci" inside "repositories"
deploy_all "atraci"
