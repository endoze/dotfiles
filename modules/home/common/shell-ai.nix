{ config, pkgs, lib, ... }:

let
  shell-ai = pkgs.buildGoModule {
    pname = "shell-ai";
    version = "1.0.0";

    src = pkgs.fetchFromGitHub {
      owner = "endoze";
      repo = "shell-ai";
      rev = "bdf669cfdae1948f41b08ebf65405ab263af3956";
      sha256 = "Vv/iwfvjpbuVbAaSWN4cBtqf1O4CUIyvVEsxaUvxybA=";
    };

    vendorHash = "sha256-xweox+LW0qaDF6yWMQFyLu++JUqejwmKNmcQKUfdF68=";

    subPackages = [ "." ];
  };
in
{
  home.packages = [ shell-ai ];
}
