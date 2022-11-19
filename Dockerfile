FROM ubuntu:20.04

ARG APP_ROOT=/workspace
ARG BUILD_PACKAGES="build-essential apt-transport-https curl software-properties-common"
ARG DEV_PACKAGES="shared-mime-info rcm zsh git lua5.3 luarocks liblua5.3-dev ruby ruby-dev nodejs npm ripgrep gnupg neovim tzdata python3 python3-pip python3-dev tmux"

ENV BUNDLE_APP_CONFIG="$APP_ROOT/.bundle"

WORKDIR $APP_ROOT

ENV DEBIAN_FRONTEND=noninteractive

RUN ln -fs /usr/share/zoneinfo/America/New_York /etc/localtime

RUN apt-get update -y \
    && apt-get install -y $BUILD_PACKAGES \
    && add-apt-repository ppa:git-core/ppa \
    && add-apt-repository ppa:neovim-ppa/stable \
    && curl --silent --show-error --location \
      https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add - \
    && echo "deb https://deb.nodesource.com/node_18.x/ stretch main" /etc/apt/sources.list.d/nodesource.list \
    && apt update -y \
    && apt install -y --no-install-recommends $DEV_PACKAGES \
    && dpkg-reconfigure --frontend noninteractive tzdata \
    && apt-get -yqq autoclean \
    && apt-get -yqq autoremove --purge \
    && apt-get -yqq purge $(dpkg --get-selections | grep deinstall | sed s/deinstall//g) \
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
