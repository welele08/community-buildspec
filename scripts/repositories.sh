#!/bin/bash


REPOSITORIES=( $(find /vagrant/repositories -maxdepth 1 -type d -printf '%P\n') )
EMAIL_NOTIFICATIONS="${EMAIL_NOTIFICATIONS:-mudler@sabayon.org}"
MAILGUN_API_KEY="${MAILGUN_API_KEY}"
MAILGUN_DOMAIN_NAME="${MAILGUN_DOMAIN_NAME}"
MAILGUN_FROM="${MAILGUN_FROM:-Excited User <mailgun\@$MAILGUN_DOMAIN_NAME\>}"
TEMPLOG=$(mktemp)
NOW=$(date +"%Y-%m-%d")
DOCKER_PULL_IMAGE=1

[ -e /vagrant/confs/env ] && . /vagrant/confs/env

# deletes the temp directory
function cleanup {
  rm -rf "$TEMPLOG"
}

# register the cleanup function to be called on the EXIT signal
trap cleanup EXIT

die() { echo "$@" 1>&2 ; exit 1; }

update_vagrant_repo() {
	pushd /vagrant
	        git fetch --all
	        git reset --hard origin/master
	popd
}

send_email() {

local SUBJECT="${1:-Report}"
local TEXT="${2:-Something went wrong}"

[ -z "$MAILGUN_API_KEY" ] && die "You have to set MAILGUN for error reporting"
[ -z "$MAILGUN_DOMAIN_NAME" ] && die "You have to set MAILGUN for error reporting"
[ -z "$MAILGUN_FROM" ] && die "You have to set MAILGUN for error reporting"

curl -s --user "api:${MAILGUN_API_KEY}" \
    https://api.mailgun.net/v3/"$MAILGUN_DOMAIN_NAME"/messages \
     -F from="$MAILGUN_FROM" \
    -F to="$EMAIL_NOTIFICATIONS" \
    -F subject="$SUBJECT" \
    -F text="$TEXT"

}

deploy() {

local ARTIFACTS="${1}"
local SERVER="${2}"
local PORT="${3}"
# soft quit. deploy is optional for now
[ -z "$ARTIFACTS" ] && exit 0
[ -z "$SERVER" ] && exit 0
[ -z "$PORT" ] && exit 0
rsync -avPz -e "ssh -q -p $PORT" $ARTIFACTS/* $SERVER

}

vagrant_cleanup() {
	#cleanup log and artifacts
	rm -rf /vagrant/artifacts/*
	rm -rf /vagrant/logs/*
}

deploy_all() {
	local REPO="${1}"

	[ -d "/vagrant/artifacts/${REPO}/" ] || mkdir -p /vagrant/artifacts/${REPO}/

	# Local deploy:
	rsync -arvP --delete /vagrant/repositories/${REPO}/entropy_artifacts/* /vagrant/artifacts/${REPO}/
	chmod -R 444 /vagrant/artifacts/${REPO} # At least should be readable

	# Remote deploy:
	deploy "/vagrant/repositories/${REPO}/entropy_artifacts" "$DEPLOY_SERVER" "$DEPLOY_PORT"
	deploy "/vagrant/logs/" "$DEPLOY_SERVER_BUILDLOGS" "$DEPLOY_PORT"


}
