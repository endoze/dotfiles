{ pkgs, inputs, userConfig, ... }:

{
  environment.systemPackages = with pkgs; [
    hypridle
    gcr
  ];

  security.pam.services.monban.enableGnomeKeyring = true;

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

  programs.monban = {
    enable = true;
    greeterEnvironment = { WLR_RENDERER = "vulkan"; };
    greeterGroups = [ "seat" "video" "render" ];
    style = ../../../config/monban/style.css;
    background = ../../../wallpapers/woman-in-cyberpunk-city.jpg;
    lock.enable = true;
    settings = {
      log_level = "warn";
      greeter = {
        window = { monitor = 0; fullscreen = true; cursor = true; };
        style = "./style.css";
        background = { image = "./background"; blur = 20; };
        default_session = "Hyprland (uwsm-managed)";
        vars = {
          error_msg = "";
          clock = { poll = "date '+%H:%M'"; interval = 30; };
          date = { poll = "date '+%A, %B %-d'"; interval = 60; };
        };
        layout = {
          widget = "box";
          orientation = "vertical";
          halign = "center";
          valign = "center";
          spacing = 24;
          class = "login-container";
          children = [
            { widget = "label"; bind = "clock"; class = "clock"; }
            { widget = "label"; bind = "date"; class = "date"; }
            { widget = "label"; text = "Welcome back"; class = "greeting"; }
            { widget = "entry"; id = "username"; placeholder = "Username"; on_submit = "focus_password"; class = "input"; }
            { widget = "entry"; id = "password"; placeholder = "Password"; secret = true; on_submit = "attempt_login"; class = "input"; }
            {
              widget = "box";
              orientation = "horizontal";
              spacing = 12;
              halign = "center";
              children = [
                { widget = "dropdown"; id = "session"; class = "session-dropdown"; }
                { widget = "button"; text = "Login"; on_click = "attempt_login"; class = "login-button"; }
              ];
            }
            { widget = "label"; id = "error_label"; bind = "error_msg"; class = "error"; }
          ];
        };
      };
      lock = {
        style = "./style.css";
        background = { image = "./background"; blur = 20; };
        vars = {
          error_msg = "";
          clock = { poll = "date '+%H:%M'"; interval = 30; };
          date = { poll = "date '+%A, %B %-d'"; interval = 60; };
          current_user = { poll = "whoami"; interval = 86400; };
        };
        layout = {
          widget = "box";
          orientation = "vertical";
          halign = "center";
          valign = "center";
          spacing = 24;
          class = "login-container";
          children = [
            { widget = "label"; bind = "clock"; class = "clock"; }
            { widget = "label"; bind = "date"; class = "date"; }
            { widget = "label"; bind = "current_user"; class = "greeting"; }
            { widget = "entry"; id = "password"; placeholder = "Password"; secret = true; on_submit = "attempt_unlock"; class = "input"; }
            { widget = "button"; text = "Unlock"; on_click = "attempt_unlock"; class = "login-button"; }
            { widget = "label"; bind = "error_msg"; class = "error"; }
          ];
        };
      };
    };
  };

  services = {
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
    };

    seatd = {
      enable = true;
      user = userConfig.username;
      group = "seat";
    };

    gnome = {
      gnome-keyring.enable = true;
      sushi.enable = true;
    };
  };
}
