{ config, pkgs, lib, inputs, ... }:

let
  matcha = inputs.matcha.packages.${pkgs.system}.default.overrideAttrs (old: {
    goModules = old.goModules.overrideAttrs (_: {
      outputHash = "sha256-99kic9ceJm5V4RbKXbqoOyZ/lahYE1hLrYzJfNzi4V4=";
    });
  });
in
{
  home.packages = [ matcha ];
}
