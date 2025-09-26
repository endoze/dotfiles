{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    clang-tools
    cmake
    dockerfile-language-server-nodejs
    fastfetch
    fd
    gcc
    ghostty
    gitAndTools.delta
    gnumake
    htop
    less
    lua
    lua-language-server
    luarocks
    marksman
    montserrat
    ncdu
    ncurses.dev
    nerd-fonts.jetbrains-mono
    nixpkgs-fmt
    nodePackages.bash-language-server
    nodePackages.typescript-language-server
    # nodePackages.vscode-json-languageserver
    nodejs
    openssl.dev
    prettierd
    readline.dev
    ripgrep
    rustup
    tree-sitter
    unar
    unrar
    unzip
    usbutils
    vscode-langservers-extracted
    yaml-language-server
    zip
    zlib.dev
    zsh
  ];


  services = {
    gpg-agent = {
      enable = true;
      enableSshSupport = false;
      pinentry.package = pkgs.pinentry-gtk2;
    };
  };

  xdg = {
    enable = true;
    userDirs = {
      enable = true;
      createDirectories = true;
    };
  };
}
