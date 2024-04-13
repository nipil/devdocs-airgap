#!/bin/bash

# references ################################################################

# The DevDocs commit we target
DEVDOC_COMMIT=36f7025a966480d3e779860e1bc58997ee8b84c4

# install adequate bundler version for Gemfile version
BUNDLER_VERSION=2.4.6

# The DevDocs prerequisite associated with this commit
APT_PACKAGES="unzip bzip2 curl ca-certificates build-essential libyaml-dev libssl-dev libffi-dev libzip-dev libgmp-dev"
RUBY_VER=3.3
RUBY_VERSION=3.3.0
RUBY_VERSION_SHA256=96518814d9832bece92a85415a819d4893b307db5921ae1f0f751a9a89a56b7d

# default command parameters ################################################
SERVE_LISTEN="0.0.0.0" # override 'serve' with -l
SERVE_PORT=8080        # override 'serve' with -p
HOST_DIR="/host"       # override 'archive' with -h

# halt on any error #########################################################
set -e

# directory structure #######################################################
SUBDIR=$(pwd)/devdocs-airgap
RUBY_INSTALL=$SUBDIR/ruby-install
PATH=$RUBY_INSTALL/bin:$PATH

# lib #######################################################################
apt_install() {
    apt-get update &&
        apt-get install -y --no-install-recommends $APT_PACKAGES &&
        apt-get autoremove -y &&
        apt-get clean
}

get_sources() {
    curl -sS -L -O https://cache.ruby-lang.org/pub/ruby/$RUBY_VER/ruby-$RUBY_VERSION.tar.gz
    echo "$RUBY_VERSION_SHA256 ruby-$RUBY_VERSION.tar.gz" >ruby-$RUBY_VERSION.tar.gz.sha256
    curl -sS -L -O https://rubygems.org/downloads/bundler-$BUNDLER_VERSION.gem
    curl -sS -L -O https://github.com/freeCodeCamp/devdocs/archive/$DEVDOC_COMMIT.zip
    mv $DEVDOC_COMMIT.zip devdocs-$DEVDOC_COMMIT.zip
}

build_ruby() {
    sha256sum -c ruby-$RUBY_VERSION.tar.gz.sha256
    tar xf ruby-$RUBY_VERSION.tar.gz
    cd ruby-$RUBY_VERSION
    ./configure --prefix=$RUBY_INSTALL
    make
    make install
    cd ..
    find ruby-$RUBY_VERSION -delete
}

bundler_extract_deps_if_available() {
    [ -f "$1" ] || return 0
    tar -v -x -f $1
}

bundler_package_if_missing() {
    [ ! -d "vendor" ] || return 0
    bundler package
    tar -j -c -v -f "$1" .bundle vendor
}

bundler_install_local_if_vendored() {
    [ -d "vendor" ] || return 0
    bundler install --local
}

setup_devdocs() {
    gem install bundler-$BUNDLER_VERSION.gem
    unzip devdocs-$DEVDOC_COMMIT.zip
    cd devdocs-$DEVDOC_COMMIT
    bundler_extract_deps_if_available ../bundle-devdocs-$DEVDOC_COMMIT.tar.bz2
    bundler_package_if_missing ../bundle-devdocs-$DEVDOC_COMMIT.tar.bz2
    bundler_install_local_if_vendored
    cd ..
}

devdoc_serve() {
    cd devdocs-$DEVDOC_COMMIT
    rackup --host "$SERVE_LISTEN" --port "$SERVE_PORT"
    cd ..
}

make_archive() {
    tar -j -c -f $HOST_DIR/devdocs-airgap.tar.bz2 \
        dda.sh \
        ruby-$RUBY_VERSION.tar.gz \
        ruby-$RUBY_VERSION.tar.gz.sha256 \
        bundler-$BUNDLER_VERSION.gem \
        devdocs-$DEVDOC_COMMIT.zip \
        bundle-devdocs-$DEVDOC_COMMIT.tar.bz2 \
        devdocs-$DEVDOC_COMMIT/public/docs/docs.json
}

usage() {
    echo "Usage: $0 command [options]"
    echo "- $0 src"
    echo "- sudo $0 apt"
    echo "- $0 setup"
    echo "- $0 [-l 0.0.0.0] [-p 8080] serve"
    exit 1
}

# main ######################################################################

while getopts ":l:p:h:" OPTION; do
    case "${OPTION}" in
    h)
        HOST_DIR="${OPTARG}"
        ;;
    l)
        SERVE_LISTEN="${OPTARG}"
        ;;
    p)
        SERVE_PORT="${OPTARG}"
        ;;
    :)
        echo "Option -${OPTARG} requires an argument."
        usage
        ;;
    *)
        usage
        ;;
    esac
done
shift $((OPTIND - 1))

case $1 in
src)
    get_sources
    ;;
apt)
    apt_install
    ;;
setup)
    build_ruby
    setup_devdocs
    ;;
archive)
    make_archive
    ;;
serve)
    devdoc_serve
    ;;
*)
    usage
    ;;
esac
