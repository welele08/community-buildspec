#!/bin/bash
set -e

. /vagrant/scripts/repositories.sh

export REPOSITORY_NAME="community"

build_clean
