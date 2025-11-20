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

  };

  outputs = { self, nixpkgs, home-manager, nix-darwin, mac-app-util, nur, hyprland, ... }@inputs:
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
            ];
            specialArgs = {
              inherit inputs userConfig systemConfig hyprland;
              sourceRoot = self;
            };
          };
      };
    };
}
