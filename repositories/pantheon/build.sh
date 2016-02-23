#!/bin/bash
set -e

. /vagrant/scripts/repositories.sh

# Build Pantheon repository
sabayon-buildpackages pantheon-base/pantheon-shell --layman elementary

# Create repository
REPOSITORY_NAME="pantheon" REPOSITORY_DESCRIPTION="Pantheon Desktop Environment Community Repository"  sabayon-createrepo

# Deploy repository "pantheon" inside "repositories"
deploy_all "pantheon"
