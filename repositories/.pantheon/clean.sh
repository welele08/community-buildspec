#!/bin/bash
set -e

. /vagrant/scripts/repositories.sh

export REPOSITORY_NAME="pantheon"

build_clean
