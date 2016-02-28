#!/bin/bash


EMAIL_NOTIFICATIONS="${EMAIL_NOTIFICATIONS:-mudler@sabayon.org}"
MAILGUN_API_KEY="${MAILGUN_API_KEY}"
MAILGUN_DOMAIN_NAME="${MAILGUN_DOMAIN_NAME}"
MAILGUN_FROM="${MAILGUN_FROM:-Excited User <mailgun\@$MAILGUN_DOMAIN_NAME\>}"
TEMPLOG=$(mktemp)
TEMPDIR=$(mktemp -d)
NOW=$(date +"%Y-%m-%d")
export DOCKER_OPTS="-t --rm"

DOCKER_COMMIT_IMAGE=${DOCKER_COMMIT_IMAGE:-false}
CHECK_BUILD_DIFFS=${DOCKER_COMMIT_IMAGE:-true}
VAGRANT_DIR="${VAGRANT_DIR:-/vagrant}"
REPOSITORIES=( $(find ${VAGRANT_DIR}/repositories -maxdepth 1 -type d -printf '%P\n' | grep -v '^\.') )

if [ "$DOCKER_COMMIT_IMAGE" = true ]; then
  export DOCKER_OPTS="-t"
else
  export DOCKER_OPTS="-t --rm"
fi


[ -e ${VAGRANT_DIR}/confs/env ] && . ${VAGRANT_DIR}/confs/env

# deletes the temp directory
function cleanup {
  rm -rf "$TEMPLOG"
  rm -rf "$TEMPDIR"
}

# register the cleanup function to be called on the EXIT signal
trap cleanup EXIT

die() { echo "$@" 1>&2 ; exit 1; }

update_vagrant_repo() {
  pushd ${VAGRANT_DIR}
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
  rm -rf ${VAGRANT_DIR}/artifacts/*
  rm -rf ${VAGRANT_DIR}/logs/*
}

deploy_all() {
  local REPO="${1}"
  
  [ -d "${VAGRANT_DIR}/artifacts/${REPO}/" ] || mkdir -p ${VAGRANT_DIR}/artifacts/${REPO}/
  
  # Local deploy:
  #rsync -arvP --delete ${VAGRANT_DIR}/repositories/${REPO}/entropy_artifacts/* ${VAGRANT_DIR}/artifacts/${REPO}/
  #chmod -R 444 ${VAGRANT_DIR}/artifacts/${REPO} # At least should be readable
  
  # Remote deploy:
  deploy "${VAGRANT_DIR}/repositories/${REPO}/entropy_artifacts" "$DEPLOY_SERVER" "$DEPLOY_PORT"
  deploy "${VAGRANT_DIR}/logs/" "$DEPLOY_SERVER_BUILDLOGS" "$DEPLOY_PORT"
  
  
}

build_all() {
  local BUILD_ARGS="$@"
  
  
  [ -z "$REPOSITORY_NAME" ] && echo "warning: repository name (REPOSITORY_NAME) not defined, using your current working directory name"
  REPOSITORY_NAME="${REPOSITORY_NAME:-$(basename $(dirname $0))}"
  
  local OLD_BINHOST_MD5=$(mktemp -t "$(basename $0).XXXXXXXXXX")
  local NEW_BINHOST_MD5=$(mktemp -t "$(basename $0).XXXXXXXXXX")
  
  if [ "$CHECK_BUILD_DIFFS" = true ]; then
    local PACKAGES_TMP=$(mktemp -t "$(basename $0).XXXXXXXXXX")
    #we need to get rid of Packages during md5sum, it contains TIMESTAMP that gets updated on each build (and thus changes, also if the compiled files remains the same)
    #here we are trying to see if there are diffs between the bins, not buy the metas.
    mv -f "${VAGRANT_DIR}/artifacts/${REPOSITORY_NAME}-binhost/Packages" $PACKAGES_TMP
    md5deep -j0 -r -s "${VAGRANT_DIR}/artifacts/${REPOSITORY_NAME}-binhost" > $OLD_BINHOST_MD5
    mv -f $PACKAGES_TMP "${VAGRANT_DIR}/artifacts/${REPOSITORY_NAME}-binhost/Packages"
  fi
  
  #Build repository
  OUTPUT_DIR="${VAGRANT_DIR}/artifacts/${REPOSITORY_NAME}-binhost" sabayon-buildpackages $BUILD_ARGS
  
  if [ "$DOCKER_COMMIT_IMAGE" = true ]; then
    CID=$(docker ps -aq | xargs echo | cut -d ' ' -f 1)
    if [ -n "$DOCKER_IMAGE" ]; then
      docker commit $CID $DOCKER_IMAGE
    else
      docker commit $CID sabayon/builder-amd64
    fi
    
  fi
  
  # Checking diffs
  if [ "$CHECK_BUILD_DIFFS" = true ]; then
    local PACKAGES_TMP=$(mktemp -t "$(basename $0).XXXXXXXXXX")
    mv -f "${VAGRANT_DIR}/artifacts/${REPOSITORY_NAME}-binhost/Packages" $PACKAGES_TMP
    md5deep -j0 -r -s "${VAGRANT_DIR}/artifacts/${REPOSITORY_NAME}-binhost" > $NEW_BINHOST_MD5
    local TO_INJECT=($(diff -ru $OLD_BINHOST_MD5 $NEW_BINHOST_MD5 | grep -v -e '^\+[\+]' | grep -e '^\+' | awk '{print $2}'))
    mv -f $PACKAGES_TMP "${VAGRANT_DIR}/artifacts/${REPOSITORY_NAME}-binhost/Packages"
    #if diffs are detected, regenerate the repository
    if diff -q $OLD_BINHOST_MD5 $NEW_BINHOST_MD5 >/dev/null ; then
      echo "There was no changes, repository generation prevented"
    else
      echo "${TO_INJECT[@]} packages needs to be injected"
      cp -rf "${TO_INJECT[@]}" $TEMPDIR/

      PORTAGE_ARTIFACTS="$TEMPDIR" OUTPUT_DIR="${VAGRANT_DIR}/artifacts/${REPOSITORY_NAME}" sabayon-createrepo
    fi
    
  else
    # Creating our permanent binhost
    cp -rf ${VAGRANT_DIR}/artifacts/${REPOSITORY_NAME}-binhost/* $TEMPDIR
    
    # Create repository
    PORTAGE_ARTIFACTS="$TEMPDIR" OUTPUT_DIR="${VAGRANT_DIR}/artifacts/${REPOSITORY_NAME}" sabayon-createrepo
  fi
  
  
  rm -rf $TEMPDIR/*
  [ "$CHECK_BUILD_DIFFS" = true ] && rm -rf $OLD_BINHOST_MD5 $NEW_BINHOST_MD5
  
  # Deploy repository inside "repositories"
  deploy_all "${REPOSITORY_NAME}"
  
}

build_clean() {
  [ -z "$REPOSITORY_NAME" ] && die "No Repository name passed (1 arg)"
  OUTPUT_DIR="${VAGRANT_DIR}/artifacts/${REPOSITORY_NAME}" sabayon-createrepo-cleanup
}

package_remove() {
  [ -z "$REPOSITORY_NAME" ] && die "No Repository name passed (1 arg)"
  OUTPUT_DIR="${VAGRANT_DIR}/artifacts/${REPOSITORY_NAME}" sabayon-createrepo-remove "$@"
}

automated_build() {
  local REPO_NAME=$1
  export REPOSITORY_NAME=$REPO_NAME
  [ -z "$REPO_NAME" ] && die "You called automated_build() blindly, without a reason, huh?"
  pushd ${VAGRANT_DIR}/repositories/$REPO_NAME
  ### XXX: Libchecks in there!
  send_email "[$REPO_NAME] $NOW Build" "Build started for $REPO_NAME at $NOW, temp log is on $TEMPLOG"
  [ -f "build.sh" ] && ./build.sh  1>&2 > $TEMPLOG
  mytime=$(date +%s)
  ansifilter $TEMPLOG > "${VAGRANT_DIR}/logs/$NOW/$REPO_NAME.$mytime.log"
  chmod 444 ${VAGRANT_DIR}/logs/$NOW/$REPO_NAME.$mytime.log
  send_email "[$REPO_NAME] $NOW Build" "Finished, log is available at: ${VAGRANT_DIR}/logs/$NOW/$REPO_NAME.$mytime.log"
  popd
  
}
