{ config, pkgs, lib, ... }:

{
  nixpkgs.config.allowUnfree = true;

  imports = [
    ../common/bat.nix
    ../common/fastfetch.nix
    ../common/fish.nix
    ../common/git.nix
    ../common/jujutsu.nix
    ../common/lua.nix
    ../common/lsd.nix
    ../common/mise.nix
    ../common/neovim.nix
    ../common/ruby.nix
    ../common/selene.nix
    ../common/sqruff.nix
    ../common/shell-ai.nix
    ../common/starship.nix
    ../common/tmux.nix
    ../common/weechat.nix
    ../common/worktrunk.nix
    ../common/zellij.nix
    ../common/hn-tui.nix
    ../common/matcha.nix
  ];

  home.packages = with pkgs; [
    age
    btop
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
    postgresql
    mariadb.client
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
