{
  description = "Endoze's dotfiles - Multi-platform Nix configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    claude-desktop = {
      url = "github:k3d3/claude-desktop-linux-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    eilmeldung = {
      url = "github:endoze/eilmeldung/fix/guard-glibc-includes-for-linux-only";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    elephant = {
      url = "github:abenz1267/elephant";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Source-only (flake = false): we graft this branch onto the nixpkgs eww
    # derivation via an overlay in lib/default.nix. PR #1441 -- survives the
    # StatusNotifierWatcher ownership handoff at startup (fixes empty tray).
    eww = {
      url = "github:endoze/eww/fix/status-notification-watcher";
      flake = false;
    };
    hyprland = {
      url = "github:hyprwm/Hyprland";
      # Don't follow nixpkgs - let Hyprland use its own pinned version
      # inputs.nixpkgs.follows = "nixpkgs";
    };
    mac-app-util = {
      url = "github:hraban/mac-app-util";
      # Don't follow nixpkgs - let mac-app-util use its own pinned version
      # to avoid SBCL/CL build incompatibilities
    };
    matcha = {
      url = "github:endoze/matcha/fix/scard-cgo-enabled";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    monban = {
      url = "git+ssh://git@github.com/endoze/monban?ref=target-endoze-gtk-layer-shell-fork-for-use-after-free-fix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-cachyos-kernel = {
      url = "github:xddxdd/nix-cachyos-kernel/release";
      # Do not override nixpkgs input to avoid version mismatches
    };
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    shirase = {
      url = "git+ssh://git@github.com/endoze/shirase";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    walker = {
      url = "github:abenz1267/walker";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.elephant.follows = "elephant";
    };
  };

  outputs = { self, ... }@inputs:
    let
      lib = inputs.nixpkgs.lib;

      userInfo = {
        username = "endoze";
        fullName = "Endoze";
        userEmail = "endoze@users.noreply.github.com";
        gpgKey = "10F9D3F8CE44AC75";
      };

      dotfilesLib = import ./lib { inherit inputs self userInfo; };
      inherit (dotfilesLib) mkHome mkDarwinSystem mkNixosSystem mkUserConfig mkSystemConfig nixpkgsFor checkMachines;

      # Machine registry. Every entry gets a home-manager config; `os` picks
      # the system-level builder. Validated against `machineModule` in
      # lib/default.nix - typos and bad value types fail eval clearly.
      machines = checkMachines {
        macbook = { system = "aarch64-darwin"; os = "darwin"; };
        workmac = { system = "aarch64-darwin"; os = "darwin"; };
        archimedes = { system = "x86_64-linux"; os = "nixos"; };
        dosvec = { system = "x86_64-linux"; os = "nixos"; };
        deadmau5 = {
          system = "x86_64-linux";
          os = "nixos";
          nixosExtraModules = [
            inputs.monban.nixosModules.default
            ({ ... }: { nixpkgs.overlays = [ inputs.nix-cachyos-kernel.overlays.pinned ]; })
          ];
        };
      };

      machinesWithOs = os: lib.filterAttrs (_: m: m.os == os) machines;

      # Docker is a container image, not a host. It needs a custom userConfig
      # (no GPG), a different system name, and a minimal home-manager build,
      # so it lives outside the machine registry rather than special-casing it.
      dockerUserConfig = (mkUserConfig { system = "x86_64-linux"; }) // { gpgKey = ""; };
      dockerHome = mkHome {
        name = "docker";
        system = "x86_64-linux";
        userConfig = dockerUserConfig;
        systemName = "docker-nix";
        minimal = true;
      };
    in
    {
      homeConfigurations = (lib.mapAttrs
        (name: m: mkHome {
          inherit name;
          inherit (m) system;
          extraModules = m.homeExtraModules;
        })
        machines) // { docker = dockerHome; };

      darwinConfigurations = lib.mapAttrs
        (name: m: mkDarwinSystem {
          inherit name;
          extraModules = m.darwinExtraModules;
        })
        (machinesWithOs "darwin");

      nixosConfigurations = lib.mapAttrs
        (name: m: mkNixosSystem {
          inherit name;
          extraModules = m.nixosExtraModules;
        })
        (machinesWithOs "nixos");

      packages.x86_64-linux = {
        dockerUserSetup = (import ./modules/machines/docker/system.nix {
          pkgs = nixpkgsFor.x86_64-linux;
          userConfig = dockerUserConfig;
          inherit lib;
        }).userSetupScript;

        dockerImage = (import ./modules/machines/docker/container.nix {
          pkgs = nixpkgsFor.x86_64-linux;
          userConfig = dockerUserConfig;
          systemConfig = mkSystemConfig "docker-nix";
          sourceRoot = self;
          inherit inputs lib;
        }).dockerImage;

        mise-compile = (import ./modules/system/nixos/mise-fhs-env.nix {
          pkgs = nixpkgsFor.x86_64-linux;
        }).package;
      };

      devShells.x86_64-linux.mise-compile = (import ./modules/system/nixos/mise-fhs-env.nix {
        pkgs = nixpkgsFor.x86_64-linux;
      }).shell;
    };
}
