{ config, pkgs, lib, userConfig, ... }:

{

  home.packages = with pkgs; [
    neovim

    # Language servers
    sqls
    dockerfile-language-server
    elixir-ls
    gopls
    helm-ls
    hyprls
    lua-language-server
    lua-language-server
    marksman
    nil
    bash-language-server
    typescript-language-server
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
    shfmt
    stylua

    # Image rendering (snacks.nvim)
    ghostscript
    tectonic
    mermaid-cli

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
