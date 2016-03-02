#!/bin/bash

. /vagrant/scripts/repositories.sh

export REPOSITORY_DESCRIPTION="Community Repository"

BUILD_ARGS=(
  "app-text/cherrytree::and3k-sunrise"
  "--layman and3k-sunrise"
)

build_all "${BUILD_ARGS[@]}"
