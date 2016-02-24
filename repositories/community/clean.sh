#!/bin/bash
set -e

. /vagrant/scripts/repositories.sh

# Create repository
REPOSITORY_NAME="community" OUTPUT_DIR="/vagrant/artifacts/${REPOSITORY_NAME}" sabayon-createrepo-cleanup
