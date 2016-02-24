#!/bin/bash
set -e

. /vagrant/scripts/repositories.sh

# Build community repository
OUTPUT_DIR="/vagrant/artifacts/community-binhost" sabayon-buildpackages app-text/cherrytree \
                      --layman and3k-sunrise

# Create repository
REPOSITORY_NAME="community" REPOSITORY_DESCRIPTION="Community Repository" PORTAGE_ARTIFACTS="/vagrant/artifacts/community-binhost" OUTPUT_DIR="/vagrant/artifacts/community" sabayon-createrepo

# Deploy repository "community" locally and remotely (if configured)
#deploy_all "community"
