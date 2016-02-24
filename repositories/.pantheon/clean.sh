#!/bin/bash
set -e

. /vagrant/scripts/repositories.sh

# Create repository
REPOSITORY_NAME="pantheon" OUTPUT_DIR="/vagrant/artifacts/${REPOSITORY_NAME}" sabayon-createrepo-cleanup
