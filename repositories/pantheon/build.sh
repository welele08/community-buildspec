#!/bin/bash
set -e

. /vagrant/scripts/repositories.sh

# Build Pantheon repository
OUTPUT_DIR="/vagrant/artifacts/pantheon-binhost"  sabayon-buildpackages pantheon-base/pantheon-shell --layman elementary

# Create repository
REPOSITORY_NAME="pantheon" REPOSITORY_DESCRIPTION="Pantheon Desktop Environment Community Repository" PORTAGE_ARTIFACTS="/vagrant/artifacts/pantheon-binhost" OUTPUT_DIR="/vagrant/artifacts/pantheon" sabayon-createrepo

# Deploy repository "pantheon" inside "repositories"
#deploy_all "pantheon"
