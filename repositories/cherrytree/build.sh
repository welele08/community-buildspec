#!/bin/bash
set -e

. /vagrant/scripts/repositories.sh

# Build Pantheon repository
sabayon-buildpackages app-text/cherrytree --layman and3k-sunrise

# Create repository
REPOSITORY_NAME="cherrytree" REPOSITORY_DESCRIPTION="Cherrytree Community Repository"  sabayon-createrepo

# Deploy repository "pantheon" locally and remotely (if configured)
deploy_all "cherrytree"
