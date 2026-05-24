# Builders and helpers used by flake.nix.
# Imported as: import ./lib { inherit inputs self userInfo; }
{ inputs, self, userInfo }:

let
  lib = inputs.nixpkgs.lib;

  supportedSystems = [ "x86_64-linux" "aarch64-darwin" "x86_64-darwin" ];
  forAllSystems = lib.genAttrs supportedSystems;

  nixpkgsFor = forAllSystems (system: import inputs.nixpkgs {
    inherit system;
    config.allowUnfree = true;
    overlays = [
      inputs.nur.overlays.default
      (final: prev: {
        direnv = prev.direnv.overrideAttrs { doCheck = false; };
      })
    ];
  });

  isDarwin = system: builtins.elem system [ "aarch64-darwin" "x86_64-darwin" ];

  mkSystemConfig = name: { hostName = name; computerName = name; };

  mkUserConfig = { system }:
    let homeBase = if isDarwin system then "/Users" else "/home";
    in userInfo // {
      homeDirectory = "${homeBase}/${userInfo.username}";
      dotfilesPath = "${homeBase}/${userInfo.username}/.dotfiles";
    };

  mkSpecialArgs = { userConfig, systemName }: {
    inherit inputs userConfig;
    systemConfig = mkSystemConfig systemName;
    sourceRoot = self;
  };

  # minimal=true skips OS / sops / shirase modules (used by docker)
  mkHome = { name, system, userConfig ? mkUserConfig { inherit system; }, systemName ? name, extraModules ? [ ], minimal ? false }:
    let
      osModules =
        if minimal then [ ]
        else if isDarwin system then [
          inputs.mac-app-util.homeManagerModules.default
          ../modules/home/darwin.nix
        ] else [
          ../modules/home/linux.nix
        ];
      sharedModules =
        if minimal then [ ]
        else [
          inputs.sops-nix.homeManagerModules.sops
          inputs.shirase.homeManagerModules.default
        ];
    in
    inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgsFor.${system};
      modules = osModules ++ sharedModules ++ [
        ../modules/home/default.nix
        ../modules/machines/${name}/home.nix
      ] ++ extraModules;
      extraSpecialArgs = mkSpecialArgs { inherit userConfig systemName; };
    };

  mkDarwinSystem = { name, extraModules ? [ ] }:
    inputs.nix-darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      modules = [
        inputs.sops-nix.darwinModules.sops
        ../modules/system/darwin/default.nix
        ../modules/machines/${name}/system.nix
      ] ++ extraModules;
      specialArgs = mkSpecialArgs {
        userConfig = mkUserConfig { system = "aarch64-darwin"; };
        systemName = name;
      };
    };

  mkNixosSystem = { name, extraModules ? [ ] }:
    inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        inputs.sops-nix.nixosModules.sops
        ../modules/system/nixos/default.nix
        ../modules/machines/${name}/system.nix
      ] ++ extraModules;
      specialArgs = mkSpecialArgs {
        userConfig = mkUserConfig { system = "x86_64-linux"; };
        systemName = name;
      };
    };

  # Schema for a single entry in the `machines` registry. Every machine gets
  # a home-manager configuration; `os` picks which system-level builder
  # also runs for it. Machines that aren't real hosts (e.g. the docker
  # container image) live outside this registry.
  machineModule = {
    options = {
      system = lib.mkOption {
        type = lib.types.enum supportedSystems;
        description = "Nix system tuple for this machine.";
      };
      os = lib.mkOption {
        type = lib.types.enum [ "darwin" "nixos" ];
        description = "OS-level configuration built alongside home-manager.";
      };
      homeExtraModules = lib.mkOption {
        type = lib.types.listOf lib.types.unspecified;
        default = [ ];
      };
      darwinExtraModules = lib.mkOption {
        type = lib.types.listOf lib.types.unspecified;
        default = [ ];
      };
      nixosExtraModules = lib.mkOption {
        type = lib.types.listOf lib.types.unspecified;
        default = [ ];
      };
    };
  };

  # Validate the raw machine registry: the module system catches typos and
  # bad value types; the explicit check below enforces that `os` agrees
  # with the chosen `system`.
  checkMachines = raw:
    let
      evaluated = (lib.evalModules {
        modules = [
          {
            options.machines = lib.mkOption {
              type = lib.types.attrsOf (lib.types.submodule machineModule);
            };
          }
          { machines = raw; }
        ];
      }).config.machines;
      validate = name: m:
        let sysIsDarwin = isDarwin m.system; in
        if m.os == "darwin" && !sysIsDarwin then
          throw "machine '${name}': os='darwin' requires a Darwin system, got '${m.system}'"
        else if m.os == "nixos" && sysIsDarwin then
          throw "machine '${name}': os='nixos' requires a Linux system, got '${m.system}'"
        else m;
    in
    lib.mapAttrs validate evaluated;
in
{
  inherit nixpkgsFor isDarwin mkSystemConfig mkUserConfig mkHome mkDarwinSystem mkNixosSystem checkMachines;
}
