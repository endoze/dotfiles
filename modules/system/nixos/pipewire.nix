{ pkgs, lib, ... }:

{
  environment.systemPackages = with pkgs; [
    rnnoise-plugin
    helvum
  ];

  security.pam.loginLimits = [
    { domain = "@users"; item = "nice"; type = "soft"; value = "-20"; }
    { domain = "@users"; item = "nice"; type = "hard"; value = "-20"; }
    { domain = "@users"; item = "rtprio"; type = "-"; value = "99"; }
  ];

  security.rtkit.enable = true;

  # Override rtkit-daemon service to add custom args
  systemd.services.rtkit-daemon = {
    serviceConfig.ExecStart = lib.mkForce [
      "" # Reset the command from upstream
      "${pkgs.rtkit}/libexec/rtkit-daemon --our-realtime-priority=50 --max-realtime-priority=49"
    ];
  };

  services.pipewire = {
    enable = true;
    systemWide = false;

    alsa.enable = true;
    alsa.support32Bit = true;
    audio.enable = true;
    pulse.enable = true;

    extraConfig.pipewire."08-default-rates" = {
      "context.properties" = {
        "default.clock.rate" = 48000;
        "default.clock.allowed-rates" = [ 44100 48000 88200 96000 ];
        "default.clock.min-quantum " = 16;
      };
      "context.modules" = [
        {
          name = "libpipewire-module-rt";
          args = {
            "nice.level" = -12;
            "rt.prio" = 45;
            "rt.time.soft" = 200000;
            "rt.time.hard" = 200000;
          };
          flags = [ "ifexists" "nofail" ];
        }
      ];
    };

    extraConfig.pipewire."09-main-virtual-sink" = {
      "context.modules" = [
        {
          name = "libpipewire-module-combine-stream";
          args = {
            "combine.mode" = "sink";
            "node.name" = "main-virtual-sink";
            "node.description" = "Main Virtual Sink";
            "combine.latency-compensate" = false;
            "combine.props" = {
              "audio.position" = [ "FL" "FR" ];
            };
            "stream.props" = { };
            "stream.rules" = [
              {
                matches = [
                  {
                    "media.class" = "Audio/Sink";
                    "node.name" = "alsa_output.pci-0000_00_1f.3.analog-stereo";
                  }
                ];
                actions = {
                  create-stream = {
                    "combine.audio.position" = [ "FL" "FR" ];
                    "audio.position" = [ "FL" "FR" ];
                  };
                };
              }
              {
                matches = [
                  {
                    "media.class" = "Audio/Sink";
                    "node.name" = "alsa_output.usb-SteelSeries_Arctis_Pro_Wireless-00.stereo-game";
                  }
                ];
                actions = {
                  create-stream = {
                    "combine.audio.position" = [ "FL" "FR" ];
                    "audio.position" = [ "FL" "FR" ];
                  };
                };
              }
            ];
          };
        }
      ];
    };

    extraConfig.pipewire."10-main-virtual-source" = {
      "context.modules" = [
        {
          name = "libpipewire-module-combine-stream";
          args = {
            "combine.mode" = "source";
            "node.name" = "main-virtual-source";
            "node.description" = "Main Virtual Source";
            "combine.latency-compensate" = false;
            "combine.props" = {
              "audio.position" = [ "FL" "FR" ];
            };
            "stream.props" = { };
            "stream.rules" = [
              {
                matches = [
                  {
                    "media.class" = "Audio/Source";
                    "node.name" = "rnnoise_source";
                  }
                ];
                actions = {
                  create-stream = {
                    "combine.audio.position" = [ "FL" "FR" ];
                    "audio.position" = [ "FL" "FR" ];
                  };
                };
              }
            ];
          };
        }
      ];
    };

    extraConfig.pipewire."11-denoise-config" = {
      "context.modules" = [
        {
          "name" = "libpipewire-module-filter-chain";
          "args" = {
            "node.description" = "Noise Canceling Source";
            "media.name" = "noise-canceling-source";
            "filter.graph" = {
              "nodes" = [
                {
                  "type" = "ladspa";
                  "name" = "rnnoise";
                  "plugin" = "${pkgs.rnnoise-plugin}/lib/ladspa/librnnoise_ladspa.so";
                  "label" = "noise_suppressor_stereo";
                  "control" = {
                    "VAD Threshold (%)" = 90.0;
                  };
                }
              ];
            };
            "audio.position" = [ "FL" "FR" ];
            "capture.props" = {
              "node.name" = "capture.rnnoise_source";
              "node.passive" = true;
              "node.target" = "alsa_input.usb-Blue_Microphones_Yeti_Stereo_Microphone_RqV8-00.analog-stereo";

            };
            "playback.props" = {
              "node.name" = "rnnoise_source";
              "media.class" = "Audio/Source";
              "node.target" = "";
            };
          };
        }
      ];
    };

    # extraConfig.pipewire-pulse."increase-quants" = {
    #   "pulse.properties" = {
    #     "pulse.min.req" = "256/48000";
    #     "pulse.min.frag" = "256/48000";
    #     "pulse.min.quantum" = "256/48000";
    #   };
    # };

    wireplumber = {
      enable = true;
      package = pkgs.wireplumber;
    };
  };
}
