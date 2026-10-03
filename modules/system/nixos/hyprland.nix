{ pkgs, inputs, userConfig, ... }:

{
  environment.systemPackages = with pkgs; [
    hypridle
    gcr_4
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
        # Minimal: date + big clock near the top, user line + password pill in
        # the lower half, no card and no submit button. Enter submits; the arrow
        # inside the field is an overlay button that shows while the field has focus.
        layout = {
          widget = "box";
          orientation = "vertical";
          halign = "fill";
          valign = "fill";
          vexpand = true;
          spacing = 10;
          class = "login-screen";
          children = [
            { widget = "box"; height = 90; }
            { widget = "label"; bind = "date"; class = "date"; halign = "center"; }
            { widget = "label"; bind = "clock"; class = "clock"; halign = "center"; }
            { widget = "box"; vexpand = true; }
            { widget = "label"; text = "Welcome back"; class = "greeting"; halign = "center"; }
            { widget = "entry"; id = "username"; placeholder = "Username"; on_submit = "focus_password"; class = "input"; halign = "center"; }
            {
              widget = "overlay";
              class = "pw-overlay";
              halign = "center";
              children = [
                { widget = "entry"; id = "password"; placeholder = "Enter Password"; secret = true; on_submit = "attempt_login"; class = "input"; }
                { widget = "button"; text = "→"; on_click = "attempt_login"; class = "pw-arrow"; halign = "end"; valign = "center"; }
              ];
            }
            { widget = "dropdown"; id = "session"; class = "session-dropdown"; halign = "center"; }
            { widget = "label"; id = "error_label"; bind = "error_msg"; class = "error"; halign = "center"; }
            { widget = "box"; height = 110; }
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
          halign = "fill";
          valign = "fill";
          vexpand = true;
          spacing = 10;
          class = "login-screen";
          children = [
            { widget = "box"; height = 90; }
            { widget = "label"; bind = "date"; class = "date"; halign = "center"; }
            { widget = "label"; bind = "clock"; class = "clock"; halign = "center"; }
            { widget = "box"; vexpand = true; }
            { widget = "label"; bind = "current_user"; class = "greeting"; halign = "center"; }
            {
              widget = "overlay";
              class = "pw-overlay";
              halign = "center";
              children = [
                { widget = "entry"; id = "password"; placeholder = "Enter Password"; secret = true; on_submit = "attempt_unlock"; class = "input"; }
                { widget = "button"; text = "→"; on_click = "attempt_unlock"; class = "pw-arrow"; halign = "end"; valign = "center"; }
              ];
            }
            { widget = "label"; bind = "error_msg"; class = "error"; halign = "center"; }
            { widget = "box"; height = 110; }
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
