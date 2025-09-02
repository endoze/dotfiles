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

  };

  outputs = { self, nixpkgs, home-manager, nix-darwin, ... }@inputs:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-darwin" "x86_64-darwin" ];

      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      nixpkgsFor = forAllSystems (system: import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      });

      localConfig = import ./modules/users.nix {
        sourceRoot = ./.;
      };
    in
    {
      homeConfigurations = {
        "linux" =
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
              ./modules/machines/linux-desktop/home.nix
            ];
            extraSpecialArgs = {
              inherit inputs userConfig systemConfig;
              username = userConfig.username;
              homeDirectory = userConfig.homeDirectory;
              userEmail = userConfig.userEmail;
              gpgKey = userConfig.gpgKey;
              sourceRoot = self;
            };
          };

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
              ./modules/home/default.nix
              ./modules/home/darwin.nix
              ./modules/machines/macbook/home.nix
            ];
            extraSpecialArgs = {
              inherit inputs userConfig systemConfig;
              username = userConfig.username;
              homeDirectory = userConfig.homeDirectory;
              userEmail = userConfig.userEmail;
              gpgKey = userConfig.gpgKey;
              sourceRoot = self;
            };
          };

        "work-macbook" =
          let
            userConfig = localConfig.getUserConfig {
              system = "aarch64-darwin";
            };
            systemConfig = localConfig.getSystemConfig;
          in
          home-manager.lib.homeManagerConfiguration {
            pkgs = nixpkgsFor.aarch64-darwin;
            modules = [
              ./modules/home/default.nix
              ./modules/home/darwin.nix
              ./modules/machines/macbook/home.nix
            ];
            extraSpecialArgs = {
              inherit inputs userConfig systemConfig;
              username = userConfig.username;
              homeDirectory = userConfig.homeDirectory;
              userEmail = userConfig.userEmail;
              gpgKey = userConfig.gpgKey;
              sourceRoot = self;
            };
          };

      };

      darwinConfigurations = {
        "work-macbook" =
          let
            userConfig = localConfig.getUserConfig {
              system = "aarch64-darwin";
            };
            systemConfig = localConfig.getSystemConfig;
          in
          nix-darwin.lib.darwinSystem {
            system = "aarch64-darwin";
            modules = [
              ./modules/os/darwin.nix
              ./modules/machines/macbook/system.nix
            ];
            specialArgs = {
              inherit inputs userConfig systemConfig;
              sourceRoot = self;
            };
          };
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
              ./modules/os/darwin.nix
              ./modules/machines/macbook/system.nix
            ];
            specialArgs = {
              inherit inputs userConfig systemConfig;
              sourceRoot = self;
            };
          };
      };

      nixosConfigurations = {
        "linux-desktop" =
          let
            userConfig = localConfig.getUserConfig {
              system = "x86_64-linux";
            };
            systemConfig = localConfig.getSystemConfig;
          in
          nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [
              ./modules/os/nixos.nix
              ./modules/machines/linux-desktop/system.nix
              home-manager.nixosModules.home-manager
              {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                home-manager.users.${userConfig.username} = import ./modules/home/default.nix;
                home-manager.extraSpecialArgs = {
                  inherit inputs userConfig systemConfig;
                  username = userConfig.username;
                  homeDirectory = userConfig.homeDirectory;
                  userEmail = userConfig.userEmail;
                  gpgKey = userConfig.gpgKey;
                  sourceRoot = self;
                };
              }
            ];
            specialArgs = {
              inherit inputs userConfig systemConfig;
              sourceRoot = self;
            };
          };
      };
    };
}
