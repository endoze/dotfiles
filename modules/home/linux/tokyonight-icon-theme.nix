{ pkgs, lib, ... }:

let
  repoUrl = "https://github.com/Fausto-Korpsvart/Tokyonight-GTK-Theme";
  revision = "4dc45d60bf35f50ebd9ee41f16ab63783f80dd64";
  subFolder = "icons";

  themeNames = [
    "Tokyonight-Dark-Cyan"
    "Tokyonight-Dark"
    "Tokyonight-Light"
    "Tokyonight-Moon"
  ];

  fetchedRepo = pkgs.fetchgit {
    url = repoUrl;
    rev = revision;
    sha256 = "sha256-AKZA+WCcfxDeNrNrq3XYw+SFoWd1VV2T9+CwK2y6+jA=";
  };
in
{
  home.file = lib.genAttrs themeNames (themeName: {
    source = "${fetchedRepo}/${subFolder}/${themeName}";
    target = ".icons/${themeName}";
  });
}
