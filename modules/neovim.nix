{ config, pkgs, lib, userConfig, ... }:

{

  home.packages = with pkgs; [
    neovim
    deno

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
    omnisharp-roslyn
    pyright
    taplo-lsp
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
