{ pkgs, inputs, userConfig, ... }:

{
  environment.systemPackages = with pkgs; [
    hypridle
    hyprlock
    gcr
  ];

  services.gnome.gnome-keyring.enable = true;
  security.pam.services.sddm.enableGnomeKeyring = true;


  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland = {
      enable = true;
    };
    # set the flake package
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    # make sure to also set the portal package, so that they are in sync
    portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
  };

  services = {
    displayManager = {
      defaultSession = "hyprland-uwsm";
      sddm = {
        enable = true;
        theme = "cyberpunk";
        package = pkgs.kdePackages.sddm;
        wayland = {
          enable = false;
        };
        extraPackages = with pkgs; [
          qt6.qt5compat
          qt6.qtdeclarative
        ];
        settings = {
          General = {
            GreeterEnvironment = "QT_SCALE_FACTOR=1.5,QT_FONT_DPI=144";
          };
        };
      };
    };
    # greetd = {
    #   enable = true;
    #   settings = {
    #     default_session = {
    #       command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd '${pkgs.dbus}/bin/dbus-run-session ${pkgs.hyprland}/bin/Hyprland'";
    #       user = "greeter";
    #     };
    #   };
    # };
    libinput.enable = true;
    dbus.enable = true;
    gvfs.enable = true;
    tumbler.enable = true;

    xserver = {
      enable = true;
      xkb = {
        layout = "us";
        variant = "";
      };
      excludePackages = [ pkgs.xterm ];
      videoDrivers = [ "nvidia" ];
    };

    seatd = {
      enable = true;
      user = userConfig.username;
    };

    gnome = {
      sushi.enable = true;
    };
  };
}
