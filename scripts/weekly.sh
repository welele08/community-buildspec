#!/bin/bash
# written by mudler@sabayon.org

. /vagrant/scripts/functions.sh

update_vagrant_repo

# XXX: We should use docker-companion squash for each image here.

rm -rfv /tmp/.*		
rm -rfv /tmp/*
