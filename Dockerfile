FROM ubuntu:20.04

ARG APP_ROOT=/workspace
ARG BUILD_PACKAGES="build-essential curl git zsh"
ARG DEV_PACKAGES="tzdata"

ENV BUNDLE_APP_CONFIG="$APP_ROOT/.bundle"

WORKDIR $APP_ROOT

ENV DEBIAN_FRONTEND=noninteractive

RUN ln -fs /usr/share/zoneinfo/America/New_York /etc/localtime

RUN apt-get update -y \
    && apt-get install -y $BUILD_PACKAGES \
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
