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
      # Don't follow nixpkgs - let mac-app-util use its own pinned version
      # to avoid SBCL/CL build incompatibilities
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
    nix-cachyos-kernel = {
      url = "github:xddxdd/nix-cachyos-kernel/release";
      # Do not override nixpkgs input to avoid version mismatches
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, nix-darwin, mac-app-util, nur, hyprland, nix-cachyos-kernel, sops-nix, ... }@inputs:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-darwin" "x86_64-darwin" ];

      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      nixpkgsFor = forAllSystems (system: import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [ nur.overlays.default ];
      });

      # Shared user info (same for all non-docker machines)
      userInfo = {
        username = "endoze";
        fullName = "Endoze";
        userEmail = "endoze@users.noreply.github.com";
        gpgKey = "10F9D3F8CE44AC75";
      };

      mkSystemConfig = name: { hostName = name; computerName = name; };

      # Helper: build userConfig from system type
      mkUserConfig = { system }:
        let
          homeBase =
            if builtins.elem system [ "aarch64-darwin" "x86_64-darwin" ]
            then "/Users" else "/home";
        in
        userInfo // {
          homeDirectory = "${homeBase}/${userInfo.username}";
          dotfilesPath = "${homeBase}/${userInfo.username}/.dotfiles";
        };

      # Docker has no GPG keys, so override to disable commit signing
      dockerUserConfig = (mkUserConfig { system = "x86_64-linux"; }) // {
        gpgKey = "";
      };

      mkHome = { name, system }:
        let
          isDarwin = builtins.elem system [ "aarch64-darwin" "x86_64-darwin" ];
          osSpecificModules =
            if isDarwin then [
              mac-app-util.homeManagerModules.default
              ./modules/home/darwin.nix
            ] else [
              ./modules/home/linux.nix
            ];
        in
        home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgsFor.${system};
          modules = osSpecificModules ++ [
            ./modules/home/default.nix
            ./modules/machines/${name}/home.nix
          ];
          extraSpecialArgs = {
            inherit inputs;
            userConfig = mkUserConfig { inherit system; };
            systemConfig = mkSystemConfig name;
            sourceRoot = self;
          };
        };

      mkDarwinSystem = name:
        nix-darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          modules = [
            ./modules/system/darwin/default.nix
            ./modules/machines/${name}/system.nix
          ];
          specialArgs = {
            inherit inputs;
            userConfig = mkUserConfig { system = "aarch64-darwin"; };
            systemConfig = mkSystemConfig name;
            sourceRoot = self;
          };
        };
    in
    {
      packages.x86_64-linux.dockerUserSetup =
        let
          dockerSystem = import ./modules/machines/docker/system.nix {
            pkgs = nixpkgsFor.x86_64-linux;
            userConfig = dockerUserConfig;
            lib = nixpkgs.lib;
          };
        in
        dockerSystem.userSetupScript;

      packages.x86_64-linux.dockerImage =
        let
          dockerContainer = import ./modules/machines/docker/container.nix {
            pkgs = nixpkgsFor.x86_64-linux;
            userConfig = dockerUserConfig;
            systemConfig = mkSystemConfig "docker-nix";
            inherit home-manager inputs;
            lib = nixpkgs.lib;
            sourceRoot = self;
          };
        in
        dockerContainer.dockerImage;

      homeConfigurations = {
        "macbook" = mkHome { name = "macbook"; system = "aarch64-darwin"; };
        "workmac" = mkHome { name = "workmac"; system = "aarch64-darwin"; };
        "deadmau5" = mkHome { name = "deadmau5"; system = "x86_64-linux"; };
        "dosvec" = mkHome { name = "dosvec"; system = "x86_64-linux"; };

        "docker" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgsFor.x86_64-linux;
          modules = [
            ./modules/home/default.nix
            ./modules/machines/docker/home.nix
          ];
          extraSpecialArgs = {
            inherit inputs;
            userConfig = dockerUserConfig;
            systemConfig = mkSystemConfig "docker-nix";
            sourceRoot = self;
          };
        };
      };

      darwinConfigurations = {
        "macbook" = mkDarwinSystem "macbook";
        "workmac" = mkDarwinSystem "workmac";
      };

      nixosConfigurations = {
        "deadmau5" = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./modules/system/nixos/default.nix
            ./modules/machines/deadmau5/system.nix
            ({ pkgs, ... }: {
              nixpkgs.overlays = [ nix-cachyos-kernel.overlays.pinned ];
            })
          ];
          specialArgs = {
            inherit inputs hyprland;
            userConfig = mkUserConfig { system = "x86_64-linux"; };
            systemConfig = mkSystemConfig "deadmau5";
            sourceRoot = self;
          };
        };

        # Headless home server with ZFS, k3s, NVIDIA GPU, and Coral TPU
        "dosvec" = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            sops-nix.nixosModules.sops
            ./modules/system/nixos/default.nix
            ./modules/machines/dosvec/system.nix
          ];
          specialArgs = {
            inherit inputs;
            userConfig = mkUserConfig { system = "x86_64-linux"; };
            systemConfig = mkSystemConfig "dosvec";
            sourceRoot = self;
          };
        };
      };
    };
}
