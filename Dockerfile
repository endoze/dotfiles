ARG GOLANG_VERSION=1.20.3
ARG RUST_VERSION=1.69.0
ARG RUBY_VERSION=3.2.2
ARG NODE_VERSION=20.0.0

FROM ruby:${RUBY_VERSION}-slim-bullseye as ruby-builder
FROM rust:${RUST_VERSION}-slim-bullseye as rust-builder
FROM node:${NODE_VERSION}-bullseye-slim as node-builder
FROM golang:${GOLANG_VERSION}-bullseye as go-builder

FROM buildpack-deps:22.04

ARG APP_ROOT=/workspace
ARG BUILD_PACKAGES="zsh fish rcm ripgrep luarocks libssl1.1 tmux bat fzf"

ENV BUNDLE_APP_CONFIG="$APP_ROOT/.bundle" DEBIAN_FRONTEND=noninteractive
ENV RUSTUP_HOME=/usr/local/rustup CARGO_HOME=/usr/local/cargo GOPATH=/go
ENV PATH /usr/local/cargo/bin:$GOPATH/bin:/usr/local/go/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV DOCKER=1

WORKDIR $APP_ROOT

RUN echo "deb http://security.ubuntu.com/ubuntu focal-security main" | tee /etc/apt/sources.list.d/focal-security.list \
    && apt-get update -y \
    && apt-get install -y $BUILD_PACKAGES \
    && apt-get -yqq autoclean \
    && apt-get -yqq autoremove --purge \
    && apt-get -yqq purge $(dpkg --get-selections | grep deinstall | sed s/deinstall//g) \
    && wget https://github.com/neovim/neovim/releases/download/v0.9.0/nvim-linux64.tar.gz \
    && tar xzvf nvim-linux64.tar.gz \
    && rm nvim-linux64.tar.gz \
    && mv nvim-linux64 /opt/ \
    && ln -s /opt/nvim-linux64/bin/nvim /usr/local/bin/nvim \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/cache/* /var/tmp/*

COPY --from=ruby-builder /usr/local/ /usr/local/
COPY --from=rust-builder /usr/local/rustup/ /usr/local/rustup/
COPY --from=rust-builder /usr/local/cargo /usr/local/cargo/
COPY --from=node-builder /usr/local/ /usr/local/
COPY --from=go-builder /usr/local/ /usr/local/

RUN mkdir -p "$GOPATH/src" "$GOPATH/bin" && chmod -R 1777 "$GOPATH" \
    && curl -sS https://starship.rs/install.sh | sh -s -- --yes \
    && npm install -g tree-sitter-cli

COPY . /root/.dotfiles

RUN mv ~/.dotfiles/rcrc.docker ~/.dotfiles/rcrc \
    && cd ~/.dotfiles \
    && ./setup/setup \
    && nvim --headless "+Lazy! sync" +qa \
    && nvim --headless "+Lazy! sync" "+MasonInstallAll" +qa \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/cache/* /var/tmp/*

ENV SHELL="/bin/fish"

CMD /bin/fish
