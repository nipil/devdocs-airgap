# syntax=docker/dockerfile:1
FROM debian:bookworm

# The DevDocs commit we target
ENV DEVDOC_COMMIT=36f7025a966480d3e779860e1bc58997ee8b84c4

# The DevDocs prerequisite associated with this commit
ENV BUNDLER_VERSION=2.4.6
ENV RUBY_VER=3.3
ENV RUBY_VERSION=3.3.0
ENV RUBY_VERSION_HASH=96518814d9832bece92a85415a819d4893b307db5921ae1f0f751a9a89a56b7d
ENV APT_PACKAGES="unzip bzip2 curl ca-certificates build-essential libyaml-dev libssl-dev libffi-dev libzip-dev libgmp-dev"

# required packages
RUN apt-get update && \
    apt-get -qq install -y --no-install-recommends $APT_PACKAGES && \
    apt-get -qq autoremove -y && \
    apt-get clean

# work with an unpriviledged user
RUN useradd -m devdocs
USER devdocs
WORKDIR /home/devdocs/devdocs-airgap

# build ruby
RUN curl -sS -L -O https://cache.ruby-lang.org/pub/ruby/$RUBY_VER/ruby-$RUBY_VERSION.tar.gz && \
    echo "$RUBY_VERSION_HASH ruby-$RUBY_VERSION.tar.gz" >ruby-$RUBY_VERSION.tar.gz.sha256 && \
    sha256sum -c ruby-$RUBY_VERSION.tar.gz.sha256 && \
    tar xf ruby-$RUBY_VERSION.tar.gz && \
    cd ruby-$RUBY_VERSION && \
    ./configure --prefix=/home/devdocs/ruby-install && make && make install && \
    cd .. && \
    find ruby-$RUBY_VERSION -delete

# update path to include the newly built ruby
ENV PATH=/home/devdocs/ruby-install/bin:$PATH

# install adequate bundler version for Gemfile version
RUN curl -sS -L -O https://rubygems.org/downloads/bundler-$BUNDLER_VERSION.gem && \
    gem install --silent bundler-$BUNDLER_VERSION.gem

# setup devdoc gems and get documentation
RUN curl -sS -L -O https://github.com/freeCodeCamp/devdocs/archive/$DEVDOC_COMMIT.zip && \
    mv $DEVDOC_COMMIT.zip devdocs-$DEVDOC_COMMIT.zip && \
    unzip devdocs-$DEVDOC_COMMIT.zip && \
    cd devdocs-$DEVDOC_COMMIT && \
    bundler package && \
    cd .. && \
    tar -jcf bundle-devdocs-$DEVDOC_COMMIT.tar.bz2 devdocs-$DEVDOC_COMMIT/.bundle devdocs-$DEVDOC_COMMIT/vendor

# download actual documentation data
WORKDIR /home/devdocs/devdocs-airgap/devdocs-$DEVDOC_COMMIT
RUN thor docs:download --all

# sets a compatible locale before starting the server
ENV LANG C.UTF-8

# start the server
EXPOSE 8080/tcp
CMD ["./dda.sh", "serve"]
