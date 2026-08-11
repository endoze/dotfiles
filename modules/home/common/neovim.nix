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
    # TypeScript 7 ships the native compiler as `tsc`, which also hosts the
    # language server via `tsc --lsp --stdio` (see config/nvim/lua/lsp/tsc.lua).
    typescript-go
    roslyn-ls
    pyright
    taplo
    templ
    terraform-ls
    vscode-langservers-extracted
    wgsl-analyzer
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
