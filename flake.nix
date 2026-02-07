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

    mac-app-util = {
      url = "github:hraban/mac-app-util";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland = {
      url = "github:hyprwm/Hyprland";
      # Don't follow nixpkgs - let Hyprland use its own pinned version
      # inputs.nixpkgs.follows = "nixpkgs";
    };

    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs = { self, nixpkgs, home-manager, nix-darwin, mac-app-util, nur, hyprland, chaotic, nixos-hardware, sops-nix, ... }@inputs:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-darwin" "x86_64-darwin" ];

      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      nixpkgsFor = forAllSystems (system: import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [ nur.overlays.default ];
      });

      localConfig = import ./modules/users/default.nix {
        sourceRoot = ./.;
      };
    in
    {
      # Docker user setup package (for Dockerfile-based builds)
      packages.x86_64-linux.dockerUserSetup =
        let
          pkgs = nixpkgsFor.x86_64-linux;
          userConfig = import ./modules/users/docker.nix // {
            homeDirectory = "/home/endoze";
          };
          dockerSystem = import ./modules/machines/docker/system.nix {
            inherit pkgs userConfig;
            lib = nixpkgs.lib;
          };
        in
        dockerSystem.userSetupScript;

      # Pure Nix Docker image (alternative to Dockerfile)
      packages.x86_64-linux.dockerImage =
        let
          pkgs = nixpkgsFor.x86_64-linux;
          userConfig = import ./modules/users/docker.nix // {
            homeDirectory = "/home/endoze";
          };
          systemConfig = {
            hostName = "docker-nix";
            computerName = "docker-nix";
          };
          dockerContainer = import ./modules/machines/docker/container.nix {
            inherit pkgs home-manager userConfig systemConfig inputs;
            lib = nixpkgs.lib;
            sourceRoot = self;
          };
        in
        dockerContainer.dockerImage;

      homeConfigurations = {
        "macbook" =
          let
            userConfig = localConfig.getUserConfig {
              system = "aarch64-darwin";
            };
            systemConfig = localConfig.getSystemConfig;
          in
          home-manager.lib.homeManagerConfiguration {
            pkgs = nixpkgsFor.aarch64-darwin;
            modules = [
              mac-app-util.homeManagerModules.default
              ./modules/home/default.nix
              ./modules/home/darwin.nix
              ./modules/machines/macbook/home.nix
            ];
            extraSpecialArgs = {
              inherit inputs userConfig systemConfig;
              sourceRoot = self;
            };
          };

        "workmac" =
          let
            userConfig = localConfig.getUserConfig {
              system = "aarch64-darwin";
            };
            systemConfig = localConfig.getSystemConfig;
          in
          home-manager.lib.homeManagerConfiguration {
            pkgs = nixpkgsFor.aarch64-darwin;
            modules = [
              mac-app-util.homeManagerModules.default
              ./modules/home/default.nix
              ./modules/home/darwin.nix
              ./modules/machines/workmac/home.nix
            ];
            extraSpecialArgs = {
              inherit inputs userConfig systemConfig;
              sourceRoot = self;
            };
          };

        "deadmau5" =
          let
            userConfig = localConfig.getUserConfig {
              system = "x86_64-linux";
            };
            systemConfig = localConfig.getSystemConfig;
          in
          home-manager.lib.homeManagerConfiguration {
            pkgs = nixpkgsFor.x86_64-linux;
            modules = [
              ./modules/home/default.nix
              ./modules/home/linux.nix
              ./modules/machines/deadmau5/home.nix
            ];
            extraSpecialArgs = {
              inherit inputs userConfig systemConfig;
              sourceRoot = self;
            };
          };

        "docker" =
          let
            userConfig = import ./modules/users/docker.nix // {
              homeDirectory = "/home/endoze";
            };
            systemConfig = {
              hostName = "docker-nix";
              computerName = "docker-nix";
            };
          in
          home-manager.lib.homeManagerConfiguration {
            pkgs = nixpkgsFor.x86_64-linux;
            modules = [
              ./modules/home/default.nix
              ./modules/machines/docker/home.nix
            ];
            extraSpecialArgs = {
              inherit inputs userConfig systemConfig;
              sourceRoot = self;
            };
          };

        "tiesto" =
          let
            userConfig = localConfig.getUserConfig {
              system = "x86_64-linux";
            };
            systemConfig = localConfig.getSystemConfig;
          in
          home-manager.lib.homeManagerConfiguration {
            pkgs = nixpkgsFor.x86_64-linux;
            modules = [
              ./modules/home/default.nix
              ./modules/home/linux.nix
              ./modules/machines/tiesto/home.nix
            ];
            extraSpecialArgs = {
              inherit inputs userConfig systemConfig;
              sourceRoot = self;
            };
          };

        "dosvec" =
          let
            userConfig = localConfig.getUserConfig {
              system = "x86_64-linux";
            };
            systemConfig = localConfig.getSystemConfig;
          in
          home-manager.lib.homeManagerConfiguration {
            pkgs = nixpkgsFor.x86_64-linux;
            modules = [
              ./modules/home/default.nix
              ./modules/home/linux.nix
              ./modules/machines/dosvec/home.nix
            ];
            extraSpecialArgs = {
              inherit inputs userConfig systemConfig;
              sourceRoot = self;
            };
          };
      };

      darwinConfigurations = {
        "macbook" =
          let
            userConfig = localConfig.getUserConfig {
              system = "aarch64-darwin";
            };
            systemConfig = localConfig.getSystemConfig;
          in
          nix-darwin.lib.darwinSystem {
            system = "aarch64-darwin";
            modules = [
              ./modules/system/darwin/default.nix
              ./modules/machines/macbook/system.nix
            ];
            specialArgs = {
              inherit inputs userConfig systemConfig;
              sourceRoot = self;
            };
          };

        "workmac" =
          let
            userConfig = localConfig.getUserConfig {
              system = "aarch64-darwin";
            };
            systemConfig = localConfig.getSystemConfig;
          in
          nix-darwin.lib.darwinSystem {
            system = "aarch64-darwin";
            modules = [
              ./modules/system/darwin/default.nix
              ./modules/machines/workmac/system.nix
            ];
            specialArgs = {
              inherit inputs userConfig systemConfig;
              sourceRoot = self;
            };
          };
      };

      nixosConfigurations = {
        "deadmau5" =
          let
            userConfig = localConfig.getUserConfig {
              system = "x86_64-linux";
            };
            systemConfig = localConfig.getSystemConfig;
          in
          nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [
              ./modules/system/nixos/default.nix
              ./modules/machines/deadmau5/system.nix
              chaotic.nixosModules.default
            ];
            specialArgs = {
              inherit inputs userConfig systemConfig hyprland;
              sourceRoot = self;
            };
          };

        "tiesto" =
          let
            userConfig = localConfig.getUserConfig {
              system = "x86_64-linux";
            };
            systemConfig = localConfig.getSystemConfig;
          in
          nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [
              ./modules/system/nixos/default.nix
              ./modules/machines/tiesto/system.nix
              nixos-hardware.nixosModules.apple-t2
              chaotic.nixosModules.default
            ];
            specialArgs = {
              inherit inputs userConfig systemConfig hyprland;
              sourceRoot = self;
            };
          };

        # Headless home server with ZFS, k3s, NVIDIA GPU, and Coral TPU
        "dosvec" =
          let
            userConfig = localConfig.getUserConfig {
              system = "x86_64-linux";
            };
            systemConfig = localConfig.getSystemConfig;
          in
          nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [
              sops-nix.nixosModules.sops
              ./modules/system/nixos/default.nix
              ./modules/machines/dosvec/system.nix
              # No chaotic - not needed for headless server
            ];
            specialArgs = {
              inherit inputs userConfig systemConfig;
              sourceRoot = self;
            };
          };

      };
    };
}
