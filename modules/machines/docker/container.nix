# NixOS container configuration for Docker image built with dockerTools
# This creates a pure Nix-based Docker image without using a Dockerfile
#
# Build: nix build .#packages.x86_64-linux.dockerImage
# Load: ./result | docker load
# Run:  docker run -it dotfiles-nix:latest
{ pkgs, lib, home-manager, userConfig, systemConfig, inputs, sourceRoot, ... }:

let
  # User configuration
  username = userConfig.username;
  homeDirectory = "/home/${username}";
  uid = 1000;
  gid = 100; # users group

  # Home-manager configuration for the container
  homeManagerConfig = home-manager.lib.homeManagerConfiguration {
    inherit pkgs;
    modules = [
      ../../home/default.nix
      ./home.nix
    ];
    extraSpecialArgs = {
      inherit inputs systemConfig;
      userConfig = userConfig // { inherit homeDirectory; };
      inherit sourceRoot;
    };
  };

  # Get the home-manager activation package
  hmActivation = homeManagerConfig.activationPackage;

  # The dotfiles source directory
  dotfilesSource = sourceRoot;

  # Create /etc files as a derivation
  etcFiles = pkgs.runCommand "etc-files" {} ''
    mkdir -p $out/etc

    cat > $out/etc/passwd << 'EOF'
root:x:0:0:root:/root:${pkgs.bashInteractive}/bin/bash
${username}:x:${toString uid}:${toString gid}:${username}:${homeDirectory}:${pkgs.fish}/bin/fish
nobody:x:65534:65534:Nobody:/nonexistent:/bin/false
EOF

    cat > $out/etc/group << 'EOF'
root:x:0:
users:x:100:${username}
nobody:x:65534:
EOF

    cat > $out/etc/shadow << 'EOF'
root:!:1::::::
${username}:!:1::::::
nobody:!:1::::::
EOF
    chmod 600 $out/etc/shadow

    cat > $out/etc/nsswitch.conf << 'EOF'
passwd:    files
group:     files
shadow:    files
hosts:     files dns
networks:  files
EOF

    mkdir -p $out/etc/nix
    cat > $out/etc/nix/nix.conf << 'EOF'
experimental-features = nix-command flakes
sandbox = false
EOF
  '';

  # All packages to include in the image
  imagePackages = [
    pkgs.bashInteractive
    pkgs.coreutils
    pkgs.findutils
    pkgs.gnugrep
    pkgs.gnused
    pkgs.gawk
    pkgs.gnutar
    pkgs.gzip
    pkgs.which
    pkgs.less
    pkgs.cacert
    pkgs.nix
    pkgs.git
    pkgs.fish
    hmActivation
    etcFiles
  ];

in
{
  # Build Docker image using streamLayeredImage
  dockerImage = pkgs.dockerTools.streamLayeredImage {
    name = "dotfiles-nix";
    tag = "latest";

    # Use buildEnv to properly merge packages and avoid duplicate path errors
    contents = pkgs.buildEnv {
      name = "image-root";
      paths = imagePackages;
      pathsToLink = [ "/bin" "/etc" "/lib" "/share" "/nix" ];
    };

    # Set up filesystem at build time using fakeroot
    fakeRootCommands = ''
      # Create home directory structure
      mkdir -p .${homeDirectory}/.config
      mkdir -p .${homeDirectory}/.local/share
      mkdir -p .${homeDirectory}/.local/state
      mkdir -p .${homeDirectory}/.cache
      mkdir -p .${homeDirectory}/.dotfiles

      # Copy dotfiles from source to writable location
      cp -r ${dotfilesSource}/* .${homeDirectory}/.dotfiles/ 2>/dev/null || true
      cp -r ${dotfilesSource}/.[!.]* .${homeDirectory}/.dotfiles/ 2>/dev/null || true

      # Make dotfiles writable (they come from nix store as read-only)
      chmod -R u+w .${homeDirectory}/.dotfiles

      # Create nix profile directories and set up profile symlink
      mkdir -p ./nix/var/nix/profiles/per-user/${username}
      mkdir -p ./nix/var/nix/gcroots/per-user/${username}
      ln -sf ${hmActivation} .${homeDirectory}/.nix-profile

      # Link home-manager files directly (activation script doesn't work in fakeroot)
      # Link .config entries
      for item in ${hmActivation}/home-files/.config/*; do
        name=$(basename "$item")
        ln -sf "$item" .${homeDirectory}/.config/"$name"
      done

      # Link .local/share entries
      if [ -d "${hmActivation}/home-files/.local/share" ]; then
        for item in ${hmActivation}/home-files/.local/share/*; do
          name=$(basename "$item")
          ln -sf "$item" .${homeDirectory}/.local/share/"$name"
        done
      fi

      # Link top-level dotfiles (like .bashrc, .profile, etc.)
      for item in ${hmActivation}/home-files/.*; do
        name=$(basename "$item")
        if [ "$name" != "." ] && [ "$name" != ".." ] && [ "$name" != ".config" ] && [ "$name" != ".local" ]; then
          ln -sf "$item" .${homeDirectory}/"$name"
        fi
      done

      # Create tmp directories
      mkdir -p ./tmp ./var/tmp ./run
      chmod 1777 ./tmp ./var/tmp

      # Set ownership for all user directories
      chown -R ${toString uid}:${toString gid} .${homeDirectory}
      chown -R ${toString uid}:${toString gid} ./nix/var/nix/profiles/per-user/${username}
      chown -R ${toString uid}:${toString gid} ./nix/var/nix/gcroots/per-user/${username}
    '';

    enableFakechroot = true;
    maxLayers = 125;

    config = {
      Env = [
        "USER=${username}"
        "HOME=${homeDirectory}"
        "PATH=${homeDirectory}/.nix-profile/home-path/bin:${homeDirectory}/.nix-profile/bin:/bin"
        "NIX_PATH=nixpkgs=${pkgs.path}"
        "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
        "NIX_SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
        "XDG_CONFIG_HOME=${homeDirectory}/.config"
        "XDG_DATA_HOME=${homeDirectory}/.local/share"
        "XDG_STATE_HOME=${homeDirectory}/.local/state"
        "XDG_CACHE_HOME=${homeDirectory}/.cache"
      ];
      User = "${username}";
      WorkingDir = homeDirectory;
      Cmd = [ "${pkgs.fish}/bin/fish" ];
    };
  };

  # Export the activation script for reference
  activationPackage = homeManagerConfig.activationPackage;
}
