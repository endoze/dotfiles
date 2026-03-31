{ config, pkgs, lib, userConfig, ... }:

let
  neovim-0_12_0 = let
    platform = if pkgs.stdenv.isDarwin then "macos-arm64" else "linux-x86_64";
    hash = if pkgs.stdenv.isDarwin
      then "sha256-zwE31pYXhcNJJvh5t6W1+gNxqw1uKVnjkOLwC0YWXOk="
      else "sha256-FgtpEl3vsW5gsoO2m+ES/UhQ1nrI+adSMowgrUPsNK8=";
  in pkgs.stdenv.mkDerivation {
    pname = "neovim";
    version = "0.12.0";
    src = pkgs.fetchurl {
      url = "https://github.com/neovim/neovim/releases/download/v0.12.0/nvim-${platform}.tar.gz";
      inherit hash;
    };
    sourceRoot = "nvim-${platform}";
    installPhase = ''
      mkdir -p $out
      cp -r bin lib share $out/
    '';
  };
in
{

  home.packages = with pkgs; [
    neovim-0_12_0

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
    nodePackages.bash-language-server
    nodePackages.typescript-language-server
    # TODO: uncomment when roslyn-ls binary is available in the nixpkgs cache
    # roslyn-ls
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
    nodePackages.mermaid-cli

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
