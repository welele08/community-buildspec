#!/bin/bash


REPOSITORIES=( $(find /vagrant/repositories -maxdepth 1 -type d -printf '%P\n' | grep -v '^\.') )
EMAIL_NOTIFICATIONS="${EMAIL_NOTIFICATIONS:-mudler@sabayon.org}"
MAILGUN_API_KEY="${MAILGUN_API_KEY}"
MAILGUN_DOMAIN_NAME="${MAILGUN_DOMAIN_NAME}"
MAILGUN_FROM="${MAILGUN_FROM:-Excited User <mailgun\@$MAILGUN_DOMAIN_NAME\>}"
TEMPLOG=$(mktemp)
TEMPDIR=$(mktemp -d)
NOW=$(date +"%Y-%m-%d")
export DOCKER_OPTS="-t --rm"

[ -e /vagrant/confs/env ] && . /vagrant/confs/env

# deletes the temp directory
function cleanup {
  rm -rf "$TEMPLOG"
	rm -rf "$TEMPDIR"
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
rsync -avPz --delete -e "ssh -q -p $PORT" $ARTIFACTS/* $SERVER

}

systen_upgrade() {
	# upgrade
	rsync -av -H -A -X --delete-during "rsync://rsync.at.gentoo.org/gentoo-portage/licenses/" "/usr/portage/licenses/"
	ls /usr/portage/licenses -1 | xargs -0 > /etc/entropy/packages/license.accept
	equo up
	equo u

	echo -5 | equo conf update
	equo cleanup --quick
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
	#rsync -arvP --delete /vagrant/repositories/${REPO}/entropy_artifacts/* /vagrant/artifacts/${REPO}/
	#chmod -R 444 /vagrant/artifacts/${REPO} # At least should be readable

	# Remote deploy:
	deploy "/vagrant/repositories/${REPO}/entropy_artifacts" "$DEPLOY_SERVER" "$DEPLOY_PORT"
	deploy "/vagrant/logs/" "$DEPLOY_SERVER_BUILDLOGS" "$DEPLOY_PORT"


}

build_all() {
	local BUILD_ARGS="${1}"
	[ -z "$REPOSITORY_NAME" ] && die "No Repository name passed (1 arg)"

	#Build repository
	OUTPUT_DIR="/vagrant/artifacts/${REPOSITORY_NAME}-binhost" sabayon-buildpackages $BUILD_ARGS

	# Creating our permanent binhost
	cp -rf "/vagrant/artifacts/${REPOSITORY_NAME}-binhost/*" $TEMPDIR

	# Create repository
	PORTAGE_ARTIFACTS="/vagrant/artifacts/${REPOSITORY_NAME}-binhost" OUTPUT_DIR="/vagrant/artifacts/${REPOSITORY_NAME}" sabayon-createrepo


	rm -rf $TEMPDIR/*

	# Deploy repository inside "repositories"
	#deploy_all "${REPOSITORY_NAME}"

}

build_clean() {
	[ -z "$REPOSITORY_NAME" ] && die "No Repository name passed (1 arg)"
	OUTPUT_DIR="/vagrant/artifacts/${REPOSITORY_NAME}" sabayon-createrepo-cleanup
}
