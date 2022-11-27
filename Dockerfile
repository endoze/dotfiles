FROM buildpack-deps:22.04

ARG APP_ROOT=/workspace
ARG BUILD_PACKAGES="zsh rcm nodejs npm ruby ruby-dev ripgrep luarocks"

ENV BUNDLE_APP_CONFIG="$APP_ROOT/.bundle"
ENV DEBIAN_FRONTEND=noninteractive

WORKDIR $APP_ROOT

RUN apt-get update -y \
    && apt-get install -y $BUILD_PACKAGES \
    && apt-get -yqq autoclean \
    && apt-get -yqq autoremove --purge \
    && apt-get -yqq purge $(dpkg --get-selections | grep deinstall | sed s/deinstall//g) \
    && wget https://github.com/neovim/neovim/releases/download/v0.8.1/nvim-linux64.deb \
    && dpkg -i nvim-linux64.deb \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/cache/* /var/tmp/*

RUN curl https://sh.rustup.rs -sSf | sh -s -- -y

COPY . /root/.dotfiles

RUN mv ~/.dotfiles/rcrc.docker ~/.dotfiles/rcrc

RUN cd ~/.dotfiles \
    && ./setup/setup \
    && echo "alias vim='nvim'" >> ~/.localrc \
    && /bin/zsh -c 'source ~/.zshrc'

ENV SHELL="/bin/zsh"

CMD /bin/zsh
