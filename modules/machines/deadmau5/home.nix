{ config, pkgs, lib, inputs, userConfig, ... }:

{
  nixpkgs.config.allowInsecurePredicate = pkg:
    builtins.elem (lib.getName pkg) [ "ventoy-gtk3" ];

  imports = [
    ../../home/meta/cli.nix
    ../../home/meta/gui-linux.nix
    ../../home/linux/walker.nix
    inputs.walker.homeManagerModules.default
  ];

  home.packages = with pkgs; [
    file
    ollama-cuda
    vmtouch
    rmpc
    slack
    (retroarch.withCores (cores: with cores; [
      genesis-plus-gx
      snes9x
      beetle-psx-hw
    ]))
    ventoy-full-gtk
    (inputs.claude-desktop.packages.${pkgs.stdenv.hostPlatform.system}.claude-desktop.override {
      nodePackages = { inherit (pkgs) asar; };
    })
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

  # Contain the steamwebhelper (Steam CEF) memory leak.
  # Known unfixed Valve bug (steam-for-linux #10180 / #5513 / #12323): with GPU-accelerated
  # web views enabled, steamwebhelper balloons to tens of GB and OOMs the whole session -
  # and since Steam is launched from the Hyprland keybind it shares the compositor's cgroup,
  # so the leak takes Hyprland down with it. This service's OWN cgroup is memory-capped; the
  # watcher continuously moves every steamwebhelper process into it, so a runaway is
  # OOM-killed *inside the cage* (Steam simply respawns it) instead of exhausting system RAM.
  # Games and the Steam client are never moved in, so they are never capped.
  # Normal GPU web-view use is ~1-3G; bump MemoryMax if legit use ever gets killed.
  systemd.user.services.steamwebhelper-cage = {
    Unit = {
      Description = "Cage the steamwebhelper CEF memory leak in a capped cgroup";
      After = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      # This unit's own cgroup is the cage:
      MemoryAccounting = true;
      MemoryMax = "8G";
      MemorySwapMax = "0";
      KillMode = "process"; # restart/stop kills only the watcher, not the caged procs
      Restart = "always";
      RestartSec = 3;
      ExecStart = "${pkgs.writeShellApplication {
        name = "steamwebhelper-cage";
        runtimeInputs = [ pkgs.coreutils ];
        text = ''
          # Our own cgroup (this service) carries MemoryMax=8G / MemorySwapMax=0.
          line=$(cat /proc/self/cgroup)
          cage="/sys/fs/cgroup''${line#0::}"
          while :; do
            for link in /proc/[0-9]*/exe; do
              tgt=$(readlink "$link" 2>/dev/null) || continue
              case "$tgt" in
                */steamwebhelper)
                  pid=$(basename "$(dirname "$link")")
                  case "$(cat "/proc/$pid/cgroup" 2>/dev/null || true)" in
                    *steamwebhelper-cage*) : ;;
                    *) echo "$pid" > "$cage/cgroup.procs" 2>/dev/null || true ;;
                  esac
                  ;;
              esac
            done
            sleep 2
          done
        '';
      }}/bin/steamwebhelper-cage";
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
      Environment = [
        "OLLAMA_HOST=0.0.0.0"
        "OLLAMA_FLASH_ATTENTION=1" # Faster inference, less VRAM usage
        "OLLAMA_KV_CACHE_TYPE=q8_0" # Quantized KV cache (~50% VRAM savings, negligible quality loss)
        "OLLAMA_KEEP_ALIVE=10m" # Unload model from VRAM after 10 min idle
      ];
      ExecStart = "${pkgs.ollama-cuda}/bin/ollama serve";
      Restart = "on-failure";
      RestartSec = "5";
    };
    # No Install.WantedBy = disabled on boot
  };

  services.mpd = {
    enable = true;
    musicDirectory = "${config.home.homeDirectory}/Music";
    extraConfig = ''
      audio_output {
        type "pipewire"
        name "PipeWire Sound Server"
      }
    '';
  };

  xdg.userDirs = {
    enable = true;
    createDirectories = true;
  };
}
