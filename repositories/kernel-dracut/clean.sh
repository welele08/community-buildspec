#!/bin/bash
set -e

. /vagrant/scripts/repositories.sh

# Create repository
REPOSITORY_NAME="kernel-dracut" OUTPUT_DIR="/vagrant/artifacts/${REPOSITORY_NAME}" sabayon-createrepo-cleanup
