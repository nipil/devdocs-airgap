# devdocs-airgap

Host a mirror of [DevDocs.io](https://devdocs.io/) on a machine without any internet access.

Thanks to [freeCodeCamp](https://github.com/freeCodeCamp) for the great tool they provide.

This is useful in corporate environment where security rules prevent ANY outside access.

Building takes quite a long time, so be patient.

# With Docker

Image size is about 14-18 GB

## First, work online

Build a self-contained image containing everything needed (~15 mins) :

    docker build --pull --rm -f "Dockerfile" -t devdocsairgap:latest "."

## Move to an air-gapped Docker environment

Export your image, move it to your air-gapped Docker environment.

Finaly, run it :

    docker run --rm -it -p 8080:8080/tcp devdocsairgap:latest

Then point your browser to http://localhost:8080

## Or export a non-Docker, standalone-archive

Archive size is about 2.5 GB (~25 mins)

    docker run --rm -it -v.:/host -p 8080:8080/tcp devdocsairgap:latest ./dda.sh -h /host archive

See section `Then, switch to air-gapped` and follow its instructions.

## You can test the exported archive, using a secondary Docker image

To verify that the prepared archive actually works (~20 mins) :

    docker build --pull --rm -f "Dockerfile.test-archive" -t devdocsairgap:latest "."

Finaly, run it :

    docker run --rm -it -p 8080:8080/tcp devdocsairgap:latest

Then point your browser to http://localhost:8080

# Without Docker

This has been tested on Debian only.

## First, work online

First get everything needed :

    sudo ./dda.sh apt
    ./dda.sh src
    ./dda.sh setup

## Export a standalone-archive

Then, build an self-contained `devdocs-airgap.tar.bz2` archive :

    ./dda.sh archive

**Only `devdocs-airgap.tar.bz2` remains useful from now on.**

Everything else can be cleaned to reclaim space.

## Then, switch to air-gapped

Move this `devdocs-airgap.tar.bz2` archive to an air-gapped Debian host.

Decompress the archive and move into it.

Then, deploy everything in-situ :

    sudo ./dda.sh apt
    ./dda.sh setup

Finaly, run it :

    ./dda.sh serve

Then point your browser to http://localhost:8080

Finally, set up an autostart using your system launcher.

# Docker image structure

    $HOME/devdocs-airgap/
        ruby-install/ (compiled)
        ruby-$DDA_RV.tar.gz
        ruby-$DDA_RV.tar.gz.sha256
        ruby-$RUBY_VERSION/ (temporary)
        bundler-$BUNDLER_VERSION.gem
        bundle-devdocs-$DDA_DDC.tar.bz2
        devdocs-$DDA_DDC.zip
        devdocs-$DEVDOC_COMMIT/
            public/docs/ (fetched documentation)
