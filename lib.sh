#!/bin/bash

CONFIG_FILE=config.env
AVAILABLE_LIST=available-docs.txt
WANTED_LIST=wanted-docs.txt

APT_PKG_COMMON="unzip bzip2 curl"
APT_PKG_RUBY="build-essential libyaml-dev libssl-dev libffi-dev libzip-dev"
APT_PKG_GEMS="libgmp-dev"
APT_PACKAGES="$APT_PKG_COMMON $APT_PKG_RUBY $APT_PKG_GEMS"

err_exit() {
    echo "$1" >&2
    exit 1
}

check_env() {
    [[ -n "$1" ]] || err_exit "Env var $1 empty, fill up $CONFIG_FILE."
}

log() {
    echo "==== $@" >&2
}

load_config() {
    log "Loading configuration"
    . $CONFIG_FILE
    check_env ARTEFACTS
    mkdir -p "$ARTEFACTS"
    check_env DEVDOC_COMMIT
    check_env RUBY_HASH
    check_env RUBY_VERSION
    check_env RUBY_INSTALL_PREFIX
    check_env BUNDLER_VERSION
}

add_built_ruby_path() {
    export PATH=$RUBY_INSTALL_PREFIX/bin:$PATH
}

setup_env() {
    load_config
    add_built_ruby_path
}

installed_ruby_version() {
    local version
    version=$(echo "puts RUBY_VERSION" | ruby 2>/dev/null)
    [[ $? -eq 0 ]] || return 1
    echo $version
    return 0
}

install_ruby_if_needed() {
    local version
    version=$(installed_ruby_version)
    [[ $? -eq 0 ]] && [[ "$version" == "$RUBY_VERSION" ]] && return 0
    build_ruby
}

apt_install() {
    echo "Installing $@"
    sudo apt-get -qq install -y "$@"
}

install_apt_prerequisites() {
    local missing=$(
        comm -1 -3 \
            <(dpkg --get-selections | grep '\binstall$' | awk '{ print $1 }' | sed 's/:[^:]*$//' | sort -u) \
            <(printf '%s\n' $APT_PACKAGES | sort -u)
    )
    [[ -z "$missing" ]] && return 0
    log "Install APT packages"
    echo "Missing: $(echo $missing)"
    apt_install $missing
}

download_artefact() {
    local url="$1"
    shift
    curl -sS -L --output-dir $ARTEFACTS -O $url $@
    [[ $? -eq 0 ]] || err_exit "Error downloading $url, exiting."
}

download_ruby() {
    [ -f $ARTEFACTS/ruby-$RUBY_VERSION.tar.gz ] && return 0
    log "Downloading Ruby"
    download_artefact https://cache.ruby-lang.org/pub/ruby/3.3/ruby-$RUBY_VERSION.tar.gz
    echo "$RUBY_HASH ruby-$RUBY_VERSION.tar.gz" >$ARTEFACTS/ruby-$RUBY_VERSION.tar.gz.sha256
}

check_ruby_download() {
    local result
    log "Checking Ruby"
    cd $ARTEFACTS
    sha256sum -c ruby-$RUBY_VERSION.tar.gz.sha256
    result=$?
    cd - >/dev/null
    [[ $result -eq 0 ]] || err_exit "SHA256 invalide!"
}

build_ruby() {
    local result

    download_ruby

    log "Building Ruby"
    rm -Rf build/ruby-$RUBY_VERSION
    mkdir -p build/
    tar -C build/ -x -f $ARTEFACTS/ruby-$RUBY_VERSION.tar.gz
    cd build/ruby-$RUBY_VERSION
    ./configure --prefix=$RUBY_INSTALL_PREFIX && make && make install
    result=$?
    cd - >/dev/null
    [[ $result -eq 0 ]] || err_exit "Build failed !"
    rm -Rf build/ruby-$RUBY_VERSION
}

download_bundler() {
    [ -f $ARTEFACTS/bundler-$BUNDLER_VERSION.gem ] && return 0
    log "Downloading Bundler $BUNDLER_VERSION"
    download_artefact https://rubygems.org/downloads/bundler-$BUNDLER_VERSION.gem
}

installed_bundler_version() {
    local version
    version=$(bundler --version 2>/dev/null | awk '{ print $NF }')
    [[ $? -eq 0 ]] || return 1
    echo $version
    return 0
}

install_bundler_if_needed() {
    local version
    add_built_ruby_path
    version=$(installed_bundler_version)
    [[ $? -eq 0 ]] && [[ "$version" == "$BUNDLER_VERSION" ]] && return 0
    install_bundler
}

install_bundler() {
    download_bundler
    log "Install bundler $BUNDLER_VERSION"
    gem install --silent $ARTEFACTS/bundler-$BUNDLER_VERSION.gem
}

download_devdocs() {
    [ -f $ARTEFACTS/devdocs-$DEVDOC_COMMIT.zip ] && return 0
    log "Downloading DevDocs"
    download_artefact https://github.com/freeCodeCamp/devdocs/archive/$DEVDOC_COMMIT.zip
    mv $ARTEFACTS/$DEVDOC_COMMIT.zip $ARTEFACTS/devdocs-$DEVDOC_COMMIT.zip
}

unpack_devdocs() {
    log "Extracting DevDoc"
    rm -Rf build/devdocs-$DEVDOC_COMMIT
    unzip -q -d build/ $ARTEFACTS/devdocs-$DEVDOC_COMMIT.zip
}

package_devdocs_bundle() {
    log "Packaging gems"
    cd build/devdocs-$DEVDOC_COMMIT/
    bundler package --quiet
    result=$?
    cd - >/dev/null
    [[ $result -eq 0 ]] || err_exit "Error fetching bundler gems, exiting."
    tar -j -c -f $ARTEFACTS/bundle-devdocs-$DEVDOC_COMMIT.tar.bz2 -C build/devdocs-$DEVDOC_COMMIT/ .bundle/ vendor/
}

available_doclist() {
    local result list
    log "Building available documentation list"

    cd build/devdocs-$DEVDOC_COMMIT/
    thor docs:list >../../$AVAILABLE_LIST
    result=$?
    cd - >/dev/null
    [[ $result -eq 0 ]] || err_exit "Could not get documentation list !"
    echo "The file $AVAILABLE_LIST holds all currently available items."
    echo "Choose any, and put them in $WANTED_LIST, to get only what you wish."
    echo "If no $WANTED_LIST is present (or empty) all of $AVAILABLE_LIST will be fetched."

    # add missing trailing newline
    echo "" >>$AVAILABLE_LIST
}

download_devdocs_airgap() {
    [ -f $ARTEFACTS/devdocs-airgap-main.zip ] && return 0
    log "Downloading DevDocs-airgap"
    download_artefact https://github.com/nipil/devdocs-airgap/archive/refs/heads/main.zip
    mv $ARTEFACTS/main.zip $ARTEFACTS/devdocs-airgap-main.zip
}

main_install_online() {
    setup_env
    install_apt_prerequisites
    download_devdocs
    unpack_devdocs
    package_devdocs_bundle
    download_devdocs_airgap
    available_doclist
}

download_documentation_item() {
    local file="${1/ /_}.tar.bz2" result_thor result_tar

    if [[ -f "$ARTEFACTS/docs/$file" ]]; then
        log "Documentation '$1' --> Already cached"
        return 0
    else
        log "Documentation '$1'"
    fi

    cd build/devdocs-$DEVDOC_COMMIT/
    rm -Rf public/
    thor docs:download "$1" >/dev/null
    result_thor=$?
    mkdir -p ../../$ARTEFACTS/docs
    tar jcf ../../$ARTEFACTS/docs/$file public/
    result_tar=$?
    cd - >/dev/null

    [[ $result_thor -eq 0 ]] || err_exit "Error while downloading documentation for '$1'"
    [[ $result_tar -eq 0 ]] || err_exit "Error while compressing documentation for '$1'"
}

download_documentation() {
    # The C standard says that text files must end with a newline
    # or the data after the last newline may not be read properly.
    # ISO/IEC 9899:2011 7.21.2 Streams: Whether the last line requires
    # a terminating new-line character is implementation-defined.
    # So, do not forget the last newline !
    while read -r line; do
        [[ "$line" =~ ^\s*(#|$) ]] && continue
        download_documentation_item "$line"
    done <"$src_list"

    [[ $? -eq 0 ]] || err_exit "Could not process $src_list"
}

main_documentation_online() {
    setup_env

    # defaults to the desired list
    local src_list=$WANTED_LIST
    # fallback to the provided full list
    [ -f "$src_list" ] || src_list=$AVAILABLE_LIST

    download_documentation "$src_list"
}
