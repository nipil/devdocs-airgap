# syntax=docker/dockerfile:1
FROM debian:bookworm

# DEVDOC COMMIT TARGET
ENV DEVDOC_COMMIT=36f7025a966480d3e779860e1bc58997ee8b84c4

# DEVDOC COMMIT TARGET PREREQUISITES 
ENV BUNDLER_VERSION=2.4.6
ENV RUBY_VERSION=3.3.0
ENV RUBY_VERSION_HASH=96518814d9832bece92a85415a819d4893b307db5921ae1f0f751a9a89a56b7d

# prerequisites
RUN apt-get update \
    && apt-get -qq install -y --no-install-recommends \
    unzip bzip2 curl ca-certificates \
    build-essential libyaml-dev libssl-dev libffi-dev libzip-dev \
    libgmp-dev \
    && apt-get -qq autoremove -y \
    && apt-get clean


# switch to unpriviledged user
RUN useradd -m devdocs
USER devdocs
WORKDIR /home/devdocs

# prepare output
RUN mkdir -p output

# build ruby
RUN curl -sS -L -O \
    https://cache.ruby-lang.org/pub/ruby/3.3/ruby-$RUBY_VERSION.tar.gz \
    && echo "$RUBY_VERSION_HASH ruby-$RUBY_VERSION.tar.gz" \
    > ruby-$RUBY_VERSION.tar.gz.sha256 \
    && sha256sum -c ruby-$RUBY_VERSION.tar.gz.sha256 \
    && tar xf ruby-$RUBY_VERSION.tar.gz \
    && mv ruby-$RUBY_VERSION.tar.gz output/

# && mv ruby-$RUBY_VERSION.tar.gz.sha256 output/

WORKDIR /home/devdocs/ruby-$RUBY_VERSION
RUN ./configure --prefix=$HOME/ruby-install
RUN make
RUN make install

# update path to include newly built ruby
ENV PATH=/home/devdocs/ruby-install/bin:$PATH

WORKDIR /home/devdocs

# install adequate bundler version for Gemfile version
RUN curl -sS -L -O \
    https://rubygems.org/downloads/bundler-$BUNDLER_VERSION.gem \
    && gem install --silent bundler-$BUNDLER_VERSION.gem \
    && mv bundler-$BUNDLER_VERSION.gem output/

# get devdoc code
RUN curl -sS -L -O \
    https://github.com/freeCodeCamp/devdocs/archive/$DEVDOC_COMMIT.zip \
    && unzip $DEVDOC_COMMIT.zip \
    && mv $DEVDOC_COMMIT.zip output/devdocs-$DEVDOC_COMMIT.zip

WORKDIR /home/devdocs/devdocs-$DEVDOC_COMMIT

RUN bundler package --quiet \
    && tar -jcf \
    /home/devdocs/output/bundle-devdocs-$DEVDOC_COMMIT.tar.bz2 \
    .bundle/ vendor/

RUN thor docs:list > available-docs.txt
    
CMD ["bash"]
