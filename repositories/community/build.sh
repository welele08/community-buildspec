#!/bin/bash

. /vagrant/scripts/repositories.sh

export REPOSITORY_DESCRIPTION="Community Repository"

BUILD_ARGS=(
  "app-text/cherrytree::and3k-sunrise"
  "games-strategy/megaglest"
  "app-emulation/shashlik-bin"
  "--layman and3k-sunrise"
  "--layman anyc"
  "--layman games-overlay"
)

build_all "${BUILD_ARGS[@]}"
