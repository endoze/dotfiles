{ config, pkgs, lib, ... }:

{
  nixpkgs.config.allowUnfree = true;

  imports = [
    ../common/bat.nix
    ../common/fish.nix
    ../common/git.nix
    ../common/jujutsu.nix
    ../common/lsd.nix
    ../common/mise.nix
    ../common/neovim.nix
    ../common/ruby.nix
    ../common/selene.nix
    ../common/shell-ai.nix
    ../common/starship.nix
    ../common/tmux.nix
    ../common/weechat.nix
    ../common/hn-tui.nix
  ];

  home.packages = with pkgs; [
    chromedriver
    docker
    docker-buildx
    docker-compose
    doctl
    gh-dash
    htop
    imagemagick
    jq
    kubectl
    kubectx
    ngrok
    nix-diff
    openssl
    sops
    terraform
    tldr
    unar
    unrar
    unzip
    yq
    zip
    zsh
  ] ++ lib.optionals pkgs.stdenv.isDarwin [
    trash-cli
  ] ++ lib.optionals pkgs.stdenv.isLinux [
    clang-tools
    cmake
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
    dnsutils
    usbutils
  ];
}
