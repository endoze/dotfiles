{ config, pkgs, lib, userConfig, ... }:

{

  home.packages = with pkgs; [
    neovim

    # Language servers
    dockerfile-language-server
    elixir-ls
    gopls
    helm-ls
    hyprls
    lua-language-server
    lua-language-server
    marksman
    nil
    nodePackages.bash-language-server
    nodePackages.typescript-language-server
    roslyn-ls
    pyright
    taplo
    templ
    terraform-ls
    vscode-langservers-extracted
    yaml-language-server

    # Formatters
    black
    ktlint
    nixpkgs-fmt
    nixpkgs-fmt
    prettierd
    stylua

    # Tools
    fd
    fzf
    mkcert
    ripgrep
    tree-sitter
  ];

  xdg.configFile = {
    "nvim".source = config.lib.file.mkOutOfStoreSymlink "${userConfig.dotfilesPath}/config/nvim";
  };
}
