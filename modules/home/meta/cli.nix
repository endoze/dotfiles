{ config, pkgs, lib, ... }:

{
  nixpkgs.config.allowUnfree = true;

  imports = [
    ../common/bat.nix
    ../common/databases.nix
    ../common/eilmeldung.nix
    ../common/fastfetch.nix
    ../common/fish.nix
    ../common/git.nix
    ../common/hn-tui.nix
    ../common/jujutsu.nix
    ../common/lsd.nix
    ../common/lua.nix
    ../common/matcha.nix
    ../common/mise.nix
    ../common/neovim.nix
    ../common/ruby.nix
    ../common/selene.nix
    ../common/shell-ai.nix
    ../common/sqruff.nix
    ../common/starship.nix
    ../common/tmux.nix
    ../common/weechat.nix
    ../common/zellij.nix
  ];

  home.packages = with pkgs; [
    age
    btop
    clickhouse
    chromedriver
    docker
    docker-buildx
    docker-compose
    doctl
    frp
    gh-dash
    htop
    imagemagick
    jq
    sqlite
    k9s
    kubectl
    kubectx
    lazydocker
    ngrok
    nix-diff
    openssl
    sops
    terraform
    tldr
    unar
    unrar
    unzip
    websocat
    worktrunk
    yq
    zip
    zsh
  ] ++ lib.optionals pkgs.stdenv.isDarwin [
    trash-cli
  ] ++ lib.optionals pkgs.stdenv.isLinux [
    clang-tools
    cmake
    dnsutils
    elixir
    elixir-ls
    fastfetch
    gcc
    gnumake
    inotify-tools
    less
    lsof
    lua
    luarocks
    ncdu
    nettools
    nodejs
    procps
    psmisc
    strace
    sysstat
    tcpdump
    traceroute
    usbutils
  ];
}
