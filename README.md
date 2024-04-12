# devdocs-mirror

Host a mirror of [DevDocs.io](https://devdocs.io/) on a fully disconnected machine.

Thanks to [freeCodeCamp](https://github.com/freeCodeCamp) for the great tool they provide.

This is useful in corporate environment where security rules prevent ANY internet access.

# Build

The archive is compiled using a Docker image (~20GB required) :

    docker build --pull --rm -f "Dockerfile" -t devdocsairgap:latest "." 

INFO: Building the image takes approximately 15 minutes.

# Serve as Container

To run the webserver and serve documentation :

    docker run --rm $MODE -p 8080:8080/tcp devdocsairgap:latest 

Set `$MODE` to `-it` for interactive run, or to `-d`for daemonized run.

Then point your browser to [http://localhost:8080]

# Explore the container image 

To explore the container image :

    docker run --rm -it devdocsairgap:latest bash

If you need priviledged access, add `--user root` before the image name.

# Docker image structure

    /home/devdoc/
        ruby-install/
        devdocs-airgap/
            ruby-$DDA_RV.tar.gz
            ruby-$DDA_RV.tar.gz.sha256
            ruby-$RUBY_VERSION/ (temporary)
            bundler-$BUNDLER_VERSION.gem
            bundle-devdocs-$DDA_DDC.tar.bz2
            devdocs-$DDA_DDC.zip
            devdocs-$DEVDOC_COMMIT/
                public/docs/
