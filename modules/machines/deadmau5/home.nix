{ config, pkgs, lib, userConfig, ... }:

{
  nixpkgs.config.permittedInsecurePackages = [
    "ventoy-gtk3-1.1.10"
  ];

  home.stateVersion = "24.05";

  imports = [
    ../../home/meta/cli.nix
    ../../home/meta/gui-linux.nix
  ];

  home.packages = with pkgs; [
    ollama-cuda
    vmtouch
    slack
    (retroarch.withCores (cores: with cores; [
      genesis-plus-gx
      snes9x
      beetle-psx-hw
    ]))
    ventoy-full-gtk
  ];

  # Preload application libraries into memory for faster startup
  systemd.user.services.firefox-preload = {
    Unit = {
      Description = "Preload Firefox into memory";
      After = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.vmtouch}/bin/vmtouch -tf ${pkgs.firefox}/lib/firefox";
      RemainAfterExit = true;
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };

  systemd.user.services.discord-preload = {
    Unit = {
      Description = "Preload Discord into memory";
      After = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.vmtouch}/bin/vmtouch -tf ${pkgs.discord}/opt/Discord";
      RemainAfterExit = true;
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };

  systemd.user.services.steam-preload = {
    Unit = {
      Description = "Preload Steam into memory";
      After = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.vmtouch}/bin/vmtouch -tf ${config.home.homeDirectory}/.local/share/Steam/ubuntu12_64 ${config.home.homeDirectory}/.local/share/Steam/linux64";
      RemainAfterExit = true;
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };

  # Ollama LLM server - manually start/stop with:
  #   systemctl --user start ollama
  #   systemctl --user stop ollama
  systemd.user.services.ollama = {
    Unit = {
      Description = "Ollama LLM server";
    };
    Service = {
      Type = "simple";
      Environment = [ "OLLAMA_HOST=0.0.0.0" ];
      ExecStart = "${pkgs.ollama-cuda}/bin/ollama serve";
      Restart = "on-failure";
    };
    # No Install.WantedBy = disabled on boot
  };

  xdg.userDirs = {
    enable = true;
    createDirectories = true;
  };
}
