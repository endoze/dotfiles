{ config, pkgs, lib, inputs, ... }:

let
  matcha = inputs.matcha.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (old: {
    env = (old.env or { }) // { CGO_ENABLED = 1; };
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.pkg-config ];
    buildInputs = (old.buildInputs or [ ]) ++ [ pkgs.pcsclite ];
    goModules = old.goModules.overrideAttrs (_: {
      outputHash = "sha256-1UWz+yfIdugfqe0gmLVX9L6JFGBY1QZgFfwUO/HEpw8=";
    });
  });
in
{
  home.packages = [ matcha ];
}
