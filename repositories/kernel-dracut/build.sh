#!/bin/bash
set -e

. /vagrant/scripts/repositories.sh

export DOCKER_PULL_IMAGE=1
export EMERGE_DEFAULTS_ARGS="-k --accept-properties=-interactive --verbose --oneshot --complete-graph --buildpkg"
export REPOSITORY_NAME="kernel-dracut"
export REPOSITORY_DESCRIPTION="Kernel with dracut testing Repository"

# Build community repository
OUTPUT_DIR="/vagrant/artifacts/${REPOSITORY_NAME}-binhost" sabayon-buildpackages \
                                                                                  sys-kernel/linux-sabayon \
                                                                                  x11-drivers/nvidia-drivers::sabayon-distro \
                                                                                  x11-drivers/nvidia-drivers::sabayon-distro \
                                                                                  x11-drivers/ati-drivers::sabayon-distro \
                                                                                  x11-drivers/xf86-video-virtualbox

# Creating our permanent binhost (optional)
cp -rf "/vagrant/artifacts/${REPOSITORY_NAME}-binhost/*" $TEMPDIR

# Create repository
PORTAGE_ARTIFACTS=$TEMPDIR OUTPUT_DIR="/vagrant/artifacts/${REPOSITORY_NAME}" sabayon-createrepo

# Clean tempdir
rm -rf $TEMPDIR/*

# Deploy repository "community" locally and remotely (if configured)
#deploy_all "community"
