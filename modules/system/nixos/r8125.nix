# Realtek R8125 2.5GbE network driver
# Required for dosvec's NIC (enp5s0) — NixOS has no DKMS, so we build from source.
# Source: https://github.com/awesometic/realtek-r8125-dkms
{ config, lib, pkgs, ... }:

let
  r8125 = config.boot.kernelPackages.callPackage ({ stdenv, lib, fetchFromGitHub, kernel }:
    stdenv.mkDerivation {
      pname = "r8125";
      version = "9.016.01";

      src = fetchFromGitHub {
        owner = "awesometic";
        repo = "realtek-r8125-dkms";
        rev = "60c86586fbe22cea7ed660a629e2d1374cc26196";
        hash = "sha256-bVVIUIuQZBtJD55n60TgWR25L06v6z5WmAcZAQalzHg=";
      };

      nativeBuildInputs = kernel.moduleBuildDependencies;

      buildPhase = ''
        runHook preBuild
        make -C ${kernel.dev}/lib/modules/${kernel.modDirVersion}/build \
          M=$(pwd)/src \
          modules
        runHook postBuild
      '';

      installPhase = ''
        runHook preInstall
        install -D src/r8125.ko \
          $out/lib/modules/${kernel.modDirVersion}/updates/r8125.ko
        runHook postInstall
      '';

      meta = with lib; {
        description = "Realtek R8125 2.5GbE ethernet driver";
        homepage = "https://github.com/awesometic/realtek-r8125-dkms";
        license = licenses.gpl2Only;
        platforms = platforms.linux;
      };
    }
  ) {};
in
{
  boot.extraModulePackages = [ r8125 ];
  boot.kernelModules = [ "r8125" ];
  boot.blacklistedKernelModules = [ "r8169" ];  # Prevent r8169 from claiming the device
}
