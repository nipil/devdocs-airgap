# devdocs-mirror

Host a mirror of [DevDocs.io](https://devdocs.io/) on a fully disconnected machine.

Thanks to [freeCodeCamp](https://github.com/freeCodeCamp) for the great tool they provide.

This is useful in corporate environment where security rules prevent ANY internet access.

# Build

Building takes ~25 minutes and the image is approximately ~20GB.

Built with Docker :

    docker build --pull --rm -f "Dockerfile" -t devdocsairgap:latest "."

Built without Docker :

    # TODO

# Build a self-containing archive for airgap-use

Extracting an archive takes ~20 minutes and the archive is ~2.5GB.

Extract with Docker :

    time nice docker run --rm -it -v .:/host devdocsairgap:latest ./dda.sh archive

Extract without Docker :

    # TODO

# Serve as Container

To run the webserver and serve documentation :

    docker run --rm -it -p 8080:8080/tcp devdocsairgap:latest

Then point your browser to [http://localhost:8080]

# Explore the container image 

To explore the container image :

    docker run --rm -it devdocsairgap:latest bash

If you need priviledged access, add `--user root` before the image name.

# Docker image structure

    $HOME/devdocs-airgap/
        ruby-install/
        ruby-$DDA_RV.tar.gz
        ruby-$DDA_RV.tar.gz.sha256
        ruby-$RUBY_VERSION/ (temporary)
        bundler-$BUNDLER_VERSION.gem
        bundle-devdocs-$DDA_DDC.tar.bz2
        devdocs-$DDA_DDC.zip
        devdocs-$DEVDOC_COMMIT/
            public/docs/
