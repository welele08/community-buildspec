#!/bin/bash


EMAIL_NOTIFICATIONS="${EMAIL_NOTIFICATIONS:-mudler@sabayon.org}"
MAILGUN_API_KEY="${MAILGUN_API_KEY}"
MAILGUN_DOMAIN_NAME="${MAILGUN_DOMAIN_NAME}"
MAILGUN_FROM="${MAILGUN_FROM:-Excited User <mailgun\@$MAILGUN_DOMAIN_NAME\>}"


DOCKER_COMMIT_IMAGE=${DOCKER_COMMIT_IMAGE:-true}
CHECK_BUILD_DIFFS=${CHECK_BUILD_DIFFS:-true}
VAGRANT_DIR="${VAGRANT_DIR:-/vagrant}"

export DOCKER_OPTS="${DOCKER_OPTS:--t}" # Remember to set --rm if DOCKER_COMMIT_IMAGE: false
export DISTFILES="${VAGRANT_DIR}/distfiles"
export ENTROPY_DOWNLOADED_PACKAGES="${VAGRANT_DIR}/entropycache"
export DOCKER_EIT_IMAGE="${DOCKER_EIT_IMAGE:-sabayon/eit-amd64}"
export PORTAGE_CACHE="${PORTAGE_CACHE:-${VAGRANT_DIR}/portagecache}"
export EMERGE_DEFAULTS_ARGS="${EMERGE_DEFAULTS_ARGS:---accept-properties=-interactive -t --verbose -n --nospinner --oneshot --complete-graph --buildpkg}"
export FEATURES="parallel-fetch protect-owned -userpriv distcc"
export WEBRSYNC="${WEBRSYNC:-1}"
export PRIVATEKEY="${PRIVATEKEY:-${VAGRANT_DIR}/confs/private.key}"
export PUBKEY="${PUBKEY:-${VAGRANT_DIR}/confs/key.pub}"
export COMMUNITY_REPOSITORY_SPECS="${COMMUNITY_REPOSITORY_SPECS:-https://github.com/Sabayon/community-repositories.git}"
export ARCHES="amd64"
export KEEP_PREVIOUS_VERSIONS=1 #you can override this in build.sh
export EMERGE_SPLIT_INSTALL=0 #by default don't split emerge installation
#Irc configs, optional.
export IRC_IDENT="${IRC_IDENT:-bot sabayon scr builder}"
export IRC_NICK="${IRC_NICK:-SCRBuilder}"

URI_BASE="${URI_BASE:-http://mirror.de.sabayon.org/community/}"

[ "$DOCKER_COMMIT_IMAGE" = true ]  && export DOCKER_OPTS="-t"
[ -e ${VAGRANT_DIR}/confs/env ] && . ${VAGRANT_DIR}/confs/env

if [ "$DOCKER_COMMIT_IMAGE" = true ]; then
  export DOCKER_PULL_IMAGE=0
fi

die() { echo "$@" 1>&2 ; exit 1; }

update_repositories() {
  REPOSITORIES=( $(find ${VAGRANT_DIR}/repositories -maxdepth 1 -type d -printf '%P\n' | grep -v '^\.' | sort) )
  export REPOSITORIES
}

update_vagrant_repo() {
  pushd ${VAGRANT_DIR}
  git fetch --all
  git reset --hard origin/master
  rm -rf ${VAGRANT_DIR}/repositories
  git clone ${COMMUNITY_REPOSITORY_SPECS} ${VAGRANT_DIR}/repositories
  update_repositories
  popd
}

irc_msg() {

  local IRC_MESSAGE="${1}"

  [ -z "$IRC_MESSAGE" ] && return 1
  [ -z "$IRC_CHANNEL" ] && return 1

  echo -e "USER ${IRC_IDENT}\nNICK ${IRC_NICK}\nJOIN ${IRC_CHANNEL}\nPRIVMSG ${IRC_CHANNEL} :${IRC_MESSAGE}\nQUIT\n" \
  | nc irc.freenode.net 6667 > /dev/null || true

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

system_upgrade() {
  # upgrade
  # rsync -av -H -A -X --delete-during "rsync://rsync.at.gentoo.org/gentoo-portage/licenses/" "/usr/portage/licenses/"
  # ls /usr/portage/licenses -1 | xargs -0 > /etc/entropy/packages/license.accept
  # equo up && equo u
  # echo -5 | equo conf update
  bash ${VAGRANT_DIR}/scripts/provision.sh || true # best-effort, it does not invalidate container states at all.
  equo cleanup
}

vagrant_cleanup() {
  #cleanup log and artifacts
  rm -rf ${VAGRANT_DIR}/artifacts/*
  rm -rf ${VAGRANT_DIR}/logs/*
}

deploy_all() {
  local REPO="${1}"

  [ -d "${VAGRANT_DIR}/artifacts/${REPO}/" ] || mkdir -p ${VAGRANT_DIR}/artifacts/${REPO}/

  # Remote deploy:
  deploy "${VAGRANT_DIR}/repositories/${REPO}/entropy_artifacts" "$DEPLOY_SERVER" "$DEPLOY_PORT"
  deploy "${VAGRANT_DIR}/logs/" "$DEPLOY_SERVER_BUILDLOGS" "$DEPLOY_PORT"
}

pkg_hash() {
  local PKG="${1}"
  local HASHFILE="${2}"
  local PKG_TMP=$(mktemp -t "$(basename $0).XXXXXXXXXX")
  echo "[-] Calculating hash for $PKG"

  #yeah, it is slow, but other methods tried so far just failed.
  bunzip2 -c < "$PKG" | tar -xO | gzip -nc > "$PKG_TMP"
  local HASH=$(gzip -lv "$PKG_TMP" | awk '{if(NR>1)print $2}')

  echo "$HASH" "$PKG" >> $HASHFILE
  rm -rf $PKG_TMP
}

packages_hash() {
  local VAGRANT_DIR="${1}"
  local REPOSITORY_NAME="${2}"
  local HASH_OUTPUT="${3}"

  # cksum '{}' | awk '{ print \$10 \$2 \$3 }'

  echo "[*] Creating hash for $REPOSITORY_NAME in $VAGRANT_DIR at $HASH_OUTPUT"
  # let's do the hash of the tbz2 without xpak data
  local TBZ2s=( $(find ${VAGRANT_DIR}/artifacts/${REPOSITORY_NAME}-binhost/ -type f -iname '*.tbz2' | sort) )
  for i in "${TBZ2s[@]}"
  do
    pkg_hash "$i" ${HASH_OUTPUT}
  done
  cat ${HASH_OUTPUT}
}

function get_image(){
  local DOCKER_IMAGE="${1}"
  local DOCKER_TAGGED_IMAGE="${2}"

  if docker images | grep -q "$DOCKER_IMAGE"; then
    echo "[*] The base image exists"
  else
    docker pull "$DOCKER_IMAGE"
  fi

  if docker images | grep -q "$DOCKER_TAGGED_IMAGE"; then
    echo "[*] A tagged image already exists"
  else
    docker tag "$DOCKER_IMAGE" "$DOCKER_TAGGED_IMAGE"
  fi
}

function expire_image(){
  local DOCKER_IMAGE="${1}"
  local DOCKER_TAGGED_IMAGE="${2}"

  if docker images | grep -q "$DOCKER_TAGGED_IMAGE"; then
    docker rmi -f "$DOCKER_TAGGED_IMAGE"
  fi
  docker pull "$DOCKER_IMAGE"
  docker tag "$DOCKER_IMAGE" "$DOCKER_TAGGED_IMAGE"
}

docker_commit_latest_container(){
  local IMAGE=$1
  sleep 1
  local CID=$(docker ps -aq | xargs echo | cut -d ' ' -f 1)

  [ -z "$IMAGE" ] && die "No docker image provided (1 arg)"
  [ -z "$CID" ] && die "Couldn't detect latest running container :("

  docker commit $CID $IMAGE
  docker rm -f $CID
}

build_all() {
  local BUILD_ARGS="$@"

  local TEMPDIR=$(mktemp -d)

  [ -z "$REPOSITORY_NAME" ] && echo "warning: repository name (REPOSITORY_NAME) not defined, using your current working directory name"
  export REPOSITORY_NAME="${REPOSITORY_NAME:-$(basename $(pwd))}"
  local DOCKER_BUILDER_IMAGE="${DOCKER_IMAGE:-sabayon/builder-amd64}"
  local DOCKER_BUILDER_TAGGED_IMAGE="${DOCKER_BUILDER_IMAGE}-$REPOSITORY_NAME"

  local DOCKER_EIT_IMAGE="${DOCKER_EIT_IMAGE:-sabayon/eit-amd64}"
  local DOCKER_EIT_TAGGED_IMAGE="${DOCKER_EIT_IMAGE}-$REPOSITORY_NAME"

  local OLD_BINHOST_MD5=$(mktemp -t "$(basename $0).XXXXXXXXXX")
  local NEW_BINHOST_MD5=$(mktemp -t "$(basename $0).XXXXXXXXXX")

  #we need to get rid of Packages during md5sum, it contains TIMESTAMP that gets updated on each build (and thus changes, also if the compiled files remains the same)
  #here we are trying to see if there are diffs between the bins, not buy the metas.
  # let's do the hash of the tbz2 without xpak data
  [ "$CHECK_BUILD_DIFFS" = true ] && packages_hash $VAGRANT_DIR $REPOSITORY_NAME $OLD_BINHOST_MD5

  # Remove packages. maintainance first.
  # Sets the docker image that we will use from now on
  get_image $DOCKER_EIT_IMAGE $DOCKER_EIT_TAGGED_IMAGE
  get_image $DOCKER_BUILDER_IMAGE $DOCKER_BUILDER_TAGGED_IMAGE

  export DOCKER_IMAGE=$DOCKER_EIT_TAGGED_IMAGE
  [ -n "${TOREMOVE}" ] && package_remove ${TOREMOVE} && [ "$DOCKER_COMMIT_IMAGE" = true ] && docker_commit_latest_container $DOCKER_EIT_TAGGED_IMAGE


  # Free the cache of builder if requested.
  [ -n "$CLEAN_CACHE" ] && [ "$CLEAN_CACHE" -eq 1 ] && [ "$DOCKER_COMMIT_IMAGE" = true ] && expire_image $DOCKER_BUILDER_IMAGE $DOCKER_BUILDER_TAGGED_IMAGE

  export DOCKER_IMAGE=$DOCKER_BUILDER_TAGGED_IMAGE


  # Build packages
  OUTPUT_DIR="${VAGRANT_DIR}/artifacts/${REPOSITORY_NAME}-binhost" sabayon-buildpackages $BUILD_ARGS
  local BUILD_STATUS=$?
  [ "$DOCKER_COMMIT_IMAGE" = true ] && docker_commit_latest_container $DOCKER_BUILDER_TAGGED_IMAGE

  if [ $BUILD_STATUS -eq 0 ]
  then
    echo "Build successfully"
  else
    echo "Build phase failed. Exiting"
    docker rm -f $CID
    exit 1
  fi

  # Checking diffs
  if [ "$CHECK_BUILD_DIFFS" = true ]; then

    # let's do the hash of the tbz2 without xpak data
    packages_hash $VAGRANT_DIR $REPOSITORY_NAME $NEW_BINHOST_MD5

    local TO_INJECT=($(diff -ru $OLD_BINHOST_MD5 $NEW_BINHOST_MD5 | grep -v -e '^\+[\+]' | grep -e '^\+' | awk '{print $2}'))
    #if diffs are detected, regenerate the repository
    if diff -q $OLD_BINHOST_MD5 $NEW_BINHOST_MD5 >/dev/null ; then
      echo "No changes where detected, repository generation prevented"
      rm -rf $TEMPDIR $OLD_BINHOST_MD5 $NEW_BINHOST_MD5
      exit 0
    else
      echo "${TO_INJECT[@]} packages needs to be injected"
      cp -rf "${TO_INJECT[@]}" $TEMPDIR/
    fi
  else
    # Creating our permanent binhost
    cp -rf ${VAGRANT_DIR}/artifacts/${REPOSITORY_NAME}-binhost/* $TEMPDIR
  fi

  # Preparing Eit image.
  export DOCKER_IMAGE=$DOCKER_EIT_TAGGED_IMAGE
  # Create repository
  DOCKER_OPTS="-t" PORTAGE_ARTIFACTS="$TEMPDIR" OUTPUT_DIR="${VAGRANT_DIR}/artifacts/${REPOSITORY_NAME}" sabayon-createrepo
  [ "$DOCKER_COMMIT_IMAGE" = true ] && docker_commit_latest_container $DOCKER_EIT_TAGGED_IMAGE

  rm -rf $TEMPDIR
  [ "$CHECK_BUILD_DIFFS" = true ] && rm -rf $OLD_BINHOST_MD5 $NEW_BINHOST_MD5

  # Generating metadata
  generate_repository_metadata
  # Cleanup - old cruft/Maintenance
  build_clean
  [ "$DOCKER_COMMIT_IMAGE" = true ] && docker_commit_latest_container $DOCKER_EIT_TAGGED_IMAGE
  purge_old_packages
  [ "$DOCKER_COMMIT_IMAGE" = true ] && docker_commit_latest_container $DOCKER_EIT_TAGGED_IMAGE

  # Deploy repository inside "repositories"
  deploy_all "${REPOSITORY_NAME}"
  unset DOCKER_IMAGE
}

build_clean() {
  [ -z "$REPOSITORY_NAME" ] && die "No Repository name passed (1 arg)"
  OUTPUT_DIR="${VAGRANT_DIR}/artifacts/${REPOSITORY_NAME}" sabayon-createrepo-cleanup
}

package_remove() {
  [ -z "$REPOSITORY_NAME" ] && die "No Repository name passed (1 arg)"
  OUTPUT_DIR="${VAGRANT_DIR}/artifacts/${REPOSITORY_NAME}" sabayon-createrepo-remove "$@"
}

load_env_from_yaml() {
  local YAML_FILE=$1

  cat $YAML_FILE | shyaml get-value repository.description  &>/dev/null && export REPOSITORY_DESCRIPTION=$(cat $YAML_FILE | shyaml get-value repository.description)  # REPOSITORY_DESCRIPTION
  cat $YAML_FILE | shyaml get-value repository.maintenance.keep_previous_versions  &>/dev/null && export KEEP_PREVIOUS_VERSIONS=$(cat $YAML_FILE | shyaml get-value repository.maintenance.keep_previous_versions) # KEEP_PREVIOUS_VERSIONS
  cat $YAML_FILE | shyaml get-values repository.maintenance.remove  &>/dev/null && export TOREMOVE="$(cat $YAML_FILE | shyaml get-values repository.maintenance.remove | xargs echo)" # replaces package_remove
  cat $YAML_FILE | shyaml get-value repository.maintenance.clean_cache  &>/dev/null && export CLEAN_CACHE=$(cat $YAML_FILE | shyaml get-value repository.maintenance.clean_cache) # CLEAN_CACHE

  # recompose our BUILD_ARGS
  cat $YAML_FILE | shyaml get-values build.target &>/dev/null && BUILD_ARGS="$(cat $YAML_FILE | shyaml get-values build.target | xargs echo)"  #mixed toinstall BUILD_ARGS
  cat $YAML_FILE | shyaml get-values build.injected_target &>/dev/null && BUILD_INJECTED_ARGS="$(cat $YAML_FILE | shyaml get-values build.injected_target | xargs echo)"  #mixed toinstall BUILD_ARGS

  cat $YAML_FILE | shyaml get-values build.overlays &>/dev/null && BUILD_ARGS="${BUILD_ARGS} --layman $(cat $YAML_FILE | shyaml get-values build.overlays | xargs echo)" #--layman options
  cat $YAML_FILE | shyaml get-values build.equo.package.install &>/dev/null && BUILD_ARGS="${BUILD_ARGS} --install $(cat $YAML_FILE | shyaml get-values build.equo.package.install | xargs echo)"  #mixed --install BUILD_ARGS
  cat $YAML_FILE | shyaml get-values build.equo.package.remove &>/dev/null && BUILD_ARGS="${BUILD_ARGS} --remove $(cat $YAML_FILE | shyaml get-values build.equo.package.remove | xargs echo)"  #mixed --remove BUILD_ARGS

  cat $YAML_FILE | shyaml get-values build.equo.package.mask &>/dev/null && EQUO_MASKS="$(cat $YAML_FILE | shyaml get-values build.equo.package.mask | xargs echo)"
  cat $YAML_FILE | shyaml get-values build.equo.package.unmask &>/dev/null && EQUO_UNMASKS="$(cat $YAML_FILE | shyaml get-values build.equo.package.unmask | xargs echo)"

  export BUILD_ARGS
  export BUILD_INJECTED_ARGS
  export EQUO_MASKS
  export EQUO_UNMASKS

  cat $YAML_FILE | shyaml get-value build.docker.image  &>/dev/null && export DOCKER_IMAGE=$(cat $YAML_FILE | shyaml get-value build.docker.image) # DOCKER_IMAGE
  cat $YAML_FILE | shyaml get-value build.docker.entropy_image  &>/dev/null && export DOCKER_EIT_IMAGE=$(cat $YAML_FILE | shyaml get-value build.docker.entropy_image) # DOCKER_EIT_IMAGE
  cat $YAML_FILE | shyaml get-value build.emerge.default_args  &>/dev/null && export EMERGE_DEFAULTS_ARGS=$(cat $YAML_FILE | shyaml get-value build.emerge.default_args) # EMERGE_DEFAULTS_ARGS
  cat $YAML_FILE | shyaml get-value build.emerge.split_install  &>/dev/null && export EMERGE_SPLIT_INSTALL=$(cat $YAML_FILE | shyaml get-value build.emerge.split_install) # EMERGE_SPLIT_INSTALL
  cat $YAML_FILE | shyaml get-value build.emerge.features  &>/dev/null && export FEATURES=$(cat $YAML_FILE | shyaml get-value build.emerge.features) # FEATURES
  cat $YAML_FILE | shyaml get-value build.emerge.profile  &>/dev/null && export BUILDER_PROFILE=$(cat $YAML_FILE | shyaml get-value build.emerge.profile) # BUILDER_PROFILE
  cat $YAML_FILE | shyaml get-value build.emerge.jobs  &>/dev/null && export BUILDER_JOBS=$(cat $YAML_FILE | shyaml get-value build.emerge.jobs) # BUILDER_JOBS
  cat $YAML_FILE | shyaml get-value build.emerge.preserved_rebuild  &>/dev/null && export PRESERVED_REBUILD=$(cat $YAML_FILE | shyaml get-value build.emerge.preserved_rebuild) # PRESERVED_REBUILD
  cat $YAML_FILE | shyaml get-value build.emerge.skip_sync  &>/dev/null && export SKIP_PORTAGE_SYNC=$(cat $YAML_FILE | shyaml get-value build.emerge.skip_sync) # SKIP_PORTAGE_SYNC
  cat $YAML_FILE | shyaml get-value build.emerge.webrsync  &>/dev/null && export WEBRSYNC=$(cat $YAML_FILE | shyaml get-value build.emerge.webrsync) # WEBRSYNC
  cat $YAML_FILE | shyaml get-value build.emerge.remote_overlay  &>/dev/null && export REMOTE_OVERLAY=$(cat $YAML_FILE | shyaml get-value build.emerge.remote_overlay) # REMOTE_OVERLAY

  cat $YAML_FILE | shyaml get-value build.equo.enman_self &>/dev/null && export ENMAN_ADD_SELF=$(cat $YAML_FILE | shyaml get-values build.equo.enman_self) # ENMAN_ADD_SELF, default 1.

  cat $YAML_FILE | shyaml get-value build.equo.repositories  &>/dev/null && export ENMAN_REPOSITORIES=$(cat $YAML_FILE | shyaml get-values build.equo.repositories) # ENMAN_REPOSITORIES
  cat $YAML_FILE | shyaml get-value build.equo.repository  &>/dev/null && export ENTROPY_REPOSITORY=$(cat $YAML_FILE | shyaml get-value build.equo.repository) # ENTROPY_REPOSITORY
  cat $YAML_FILE | shyaml get-value build.equo.dependency_install.enable  &>/dev/null && export USE_EQUO=$(cat $YAML_FILE | shyaml get-value build.equo.dependency_install.enable) # USE_EQUO
  cat $YAML_FILE | shyaml get-value build.equo.dependency_install.install_atoms  &>/dev/null && export EQUO_INSTALL_ATOMS=$(cat $YAML_FILE | shyaml get-value build.equo.dependency_install.install_atoms) # EQUO_INSTALL_ATOMS

  cat $YAML_FILE | shyaml get-value build.equo.dependency_install.dependency_scan_depth  &>/dev/null && export DEPENDENCY_SCAN_DEPTH=$(cat $YAML_FILE | shyaml get-value build.equo.dependency_install.dependency_scan_depth) # DEPENDENCY_SCAN_DEPTH
  cat $YAML_FILE | shyaml get-value build.euqo.dependency_install.prune_virtuals &>/dev/null && export PRUNE_VIRTUALS # PRUNE_VIRTUALS
  cat $YAML_FILE | shyaml get-value build.equo.dependency_install.install_version  &>/dev/null && export EQUO_INSTALL_VERSION=$(cat $YAML_FILE | shyaml get-value build.equo.dependency_install.install_version) # EQUO_INSTALL_VERSION
  cat $YAML_FILE | shyaml get-value build.equo.dependency_install.split_install  &>/dev/null && export EQUO_SPLIT_INSTALL=$(cat $YAML_FILE | shyaml get-value build.equo.dependency_install.split_install) # EQUO_SPLIT_INSTALL
}

automated_build() {
  local REPO_NAME=$1
  local TEMPLOG=$(mktemp)
  [ -z "$REPO_NAME" ] && die "You called automated_build() blindly, without a reason, huh?"
  pushd ${VAGRANT_DIR}/repositories/$REPO_NAME
  ### XXX: Libchecks in there!
  irc_msg "Repository \"${REPO_NAME}\" build starting."
  env -i REPOSITORY_NAME=$REPO_NAME REPOSITORIES=$REPOSITORIES TEMPLOG=$TEMPLOG /bin/bash -c "
  . /vagrant/scripts/functions.sh
  load_env_from_yaml \"build.yaml\"
  { build_all \"\$BUILD_ARGS\"; } 1>&2 > \$TEMPLOG "
  NOW=$(date +"%Y-%m-%d")
  [ ! -d "${VAGRANT_DIR}/logs/$NOW" ] && mkdir -p ${VAGRANT_DIR}/logs/$NOW && chmod -R 755 ${VAGRANT_DIR}/logs/$NOW
  mytime=$(date +%s)
  ansifilter $TEMPLOG > "${VAGRANT_DIR}/logs/$NOW/$REPO_NAME.$mytime.log"
  chmod 755 ${VAGRANT_DIR}/logs/$NOW/$REPO_NAME.$mytime.log
  irc_msg "Repository \"${REPO_NAME}\" build completed. Log is available at: ${URI_BASE}/logs/$NOW/$REPO_NAME.$mytime.log"
  popd
  rm -rf $TEMPLOG
}

generate_metadata() {
  echo "Generating metadata"
  update_repositories
  # Generate repository list
  printf "%s\n" "${REPOSITORIES[@]}" > ${VAGRANT_DIR}/artifacts/AVAILABLE_REPOSITORIES

  echo "REPOSITORY LIST"
  echo "@@@@@@@@@@@@@@@"
  cat ${VAGRANT_DIR}/artifacts/AVAILABLE_REPOSITORIES
  # \.[a-f0-9]{40}

  perl ${VAGRANT_DIR}/scripts/community_packages_list.pl
}

generate_repository_metadata() {
  local REPOSITORY=$REPOSITORY_NAME
  local PKGLISTS=($(find ${VAGRANT_DIR}/artifacts/$REPOSITORY | grep packages.db.pkglist))

  for i in "${PKGLISTS[@]}"
  do
    IFS=$*/ command eval 'plist=($i)'
    local arch=${plist[-3]}
    local repo=${plist[-7]}
    local outputpkglist=${VAGRANT_DIR}/artifacts/$repo/PKGLIST-$arch
    cp -rf "$i" "${outputpkglist}"
    perl -pi -e 's/\.[a-f0-9]{40}//g' "${outputpkglist}"
    perl -pi -e 's/.*\/|\/|\.tbz2//g' "${outputpkglist}"
    perl -pi -e 's/\:/\//' "${outputpkglist}"
    echo "Generated packagelist: ${outputpkglist}"
  done
}

purge_old_packages() {

  local PKGLISTS=($(find ${VAGRANT_DIR}/artifacts/$REPOSITORY_NAME/ | grep PKGLIST))
  local REMOVED=0
  for i in "${PKGLISTS[@]}"
  do
    local REPO_CONTENT=$(cat ${i} | perl -lpe 's:\~.*::g' | xargs echo );
    local TOREMOVE=$(OUTPUT_REMOVED=1 PACKAGES=$REPO_CONTENT perl ${VAGRANT_DIR}/scripts/purge_old_versions.pl );
    [ -n "${TOREMOVE}" ] && let REMOVED+=1 && package_remove ${TOREMOVE}
  done

  [ $REMOVED != 0 ] && generate_repository_metadata
}


docker_clean() {
  # Best effort - cleaning orphaned containers
  docker ps -a -q | xargs -n 1 -I {} sudo docker rm {}

  # Best effort - cleaning orphaned images
  local images=$(docker images | grep '<none>' | tr -s ' ' | cut -d ' ' -f 3)
  if [ -n "${images}" ]; then
    docker rmi ${images}
  fi

}
