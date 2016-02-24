#!/bin/bash
set -e

. /vagrant/scripts/repositories.sh

export REPOSITORY_NAME="kernel-dracut"

build_clean
