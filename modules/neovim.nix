{ config, pkgs, lib, userConfig, ... }:

{

  home.packages = with pkgs; [
    neovim
    deno

    # Language servers
    lua-language-server
    nil
    nodePackages.typescript-language-server
    gopls
    pyright

    # Formatters
    nixpkgs-fmt
    black
    prettierd
    stylua

    # Tools
    tree-sitter
    ripgrep
    fd
    fzf
  ];

  xdg.configFile = {
    "nvim".source = config.lib.file.mkOutOfStoreSymlink "${userConfig.dotfilesPath}/config/nvim";
  };
}
