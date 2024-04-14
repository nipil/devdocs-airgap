# syntax=docker/dockerfile:1
FROM debian:bookworm

# unpriviledged user
USER root
RUN useradd -m devdocs

# seed
USER devdocs
RUN mkdir /home/devdocs/devdocs-airgap
WORKDIR /home/devdocs/devdocs-airgap
COPY --chown=devdocs --chmod=755 dda.sh ./

# system packages
USER root
RUN ./dda.sh apt

# get sources
USER devdocs
RUN ./dda.sh src

# setup
RUN ./dda.sh setup

# server-compatible locale
ENV LANG C.UTF-8

# start the server
EXPOSE 8080/tcp
CMD ["./dda.sh", "serve"]
