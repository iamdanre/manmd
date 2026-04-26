FROM alpine:latest

# Install shells and testing dependencies
# - bash, zsh, fish: Supported shells for manmd
# - mandoc & mandoc-apropos: Provides `man` and `man -k`
# - util-linux: Provides the `col` command
# - coreutils & coreutils-doc: Provides standard utilities and their man pages for testing
# - man-pages: Standard Linux manual pages
# - git: Useful for Dev Container source control operations
RUN apk add --no-cache \
    bash \
    zsh \
    fish \
    mandoc \
    mandoc-apropos \
    man-pages \
    util-linux \
    coreutils \
    coreutils-doc \
    git
