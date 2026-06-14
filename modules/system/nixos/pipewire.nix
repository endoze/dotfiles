{ pkgs, lib, ... }:

{
  environment.systemPackages = with pkgs; [
    rnnoise-plugin
    caps
    tap-plugins
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

    extraLadspaPackages = [ pkgs.rnnoise-plugin pkgs.caps pkgs.tap-plugins ];

    extraConfig.pipewire."08-default-rates" = {
      "context.properties" = {
        "default.clock.rate" = 48000;
        "default.clock.allowed-rates" = [ 44100 48000 88200 96000 ];
        "default.clock.quantum" = 256;
        "default.clock.min-quantum" = 64;
        "default.clock.max-quantum" = 2048;
      };
      "context.modules" = [
        {
          name = "libpipewire-module-rt";
          args = {
            "nice.level" = -12;
            "rt.prio" = 45;
            # Increase from 200ms to 2s — prevents RLIMIT_RTTIME kills during
            # plugin init (rnnoise LADSPA) or transient load spikes
            "rt.time.soft" = 2000000;
            "rt.time.hard" = 2000000;
          };
          flags = [ "ifexists" "nofail" ];
        }
      ];
    };

    extraConfig.pipewire-pulse."10-latency" = {
      "pulse.properties" = {
        "pulse.min.req" = "256/48000";
        "pulse.min.frag" = "256/48000";
        "pulse.min.quantum" = "256/48000";
        "pulse.max.quantum" = "2048/48000";
      };
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
              "audio.position" = [ "MONO" ];
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
                    "combine.audio.position" = [ "MONO" ];
                    "audio.position" = [ "MONO" ];
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
            "node.description" = "Radio Voice Source";
            "media.name" = "radio-voice-source";
            # Mono broadcast voice chain. Signal flows:
            #   rnnoise -> hp -> warmth_shelf -> mud_cut -> presence -> air
            #     -> deess -> comp -> tube -> limit -> (playback)
            # Tuned for a "Polished (moderate)" radio voice. The main knobs to
            # tweak by ear are the EQ gains, comp strength/gain, and de-ess threshold.
            "filter.graph" = {
              "nodes" = [
                {
                  "type" = "ladspa";
                  "name" = "rnnoise";
                  "plugin" = "librnnoise_ladspa";
                  "label" = "noise_suppressor_mono";
                  "control" = {
                    # 90% caused onset clipping (first syllable cut off);
                    # 75% gives aggressive noise rejection with better speech onset
                    "VAD Threshold (%)" = 75.0;
                  };
                }
                {
                  # Kill sub-bass rumble and plosive thump
                  "type" = "builtin";
                  "name" = "hp";
                  "label" = "bq_highpass";
                  "control" = { "Freq" = 85.0; "Q" = 0.7; };
                }
                {
                  # Chest/proximity warmth
                  "type" = "builtin";
                  "name" = "warmth_shelf";
                  "label" = "bq_lowshelf";
                  "control" = { "Freq" = 140.0; "Q" = 0.7; "Gain" = 2.0; };
                }
                {
                  # Scoop boxy low-mid mud
                  "type" = "builtin";
                  "name" = "mud_cut";
                  "label" = "bq_peaking";
                  "control" = { "Freq" = 320.0; "Q" = 1.2; "Gain" = -3.0; };
                }
                {
                  # Presence / intelligibility
                  "type" = "builtin";
                  "name" = "presence";
                  "label" = "bq_peaking";
                  "control" = { "Freq" = 3500.0; "Q" = 1.0; "Gain" = 4.0; };
                }
                {
                  # Air / sheen
                  "type" = "builtin";
                  "name" = "air";
                  "label" = "bq_highshelf";
                  "control" = { "Freq" = 9000.0; "Q" = 0.7; "Gain" = 3.0; };
                }
                {
                  # Tame sibilance from the presence/air boosts
                  "type" = "ladspa";
                  "name" = "deess";
                  "plugin" = "tap_deesser";
                  "label" = "tap_deesser";
                  "control" = {
                    "Threshold Level [dB]" = -6.0;
                    "Frequency [Hz]" = 6500.0;
                    "Sidechain Filter" = 0.0;
                    "Monitor" = 0.0;
                  };
                }
                {
                  # Even out levels, bring the voice forward (~3:1 feel + makeup)
                  "type" = "ladspa";
                  "name" = "comp";
                  "plugin" = "caps";
                  "label" = "Compress";
                  "control" = {
                    "measure" = 1.0;
                    "mode" = 1.0;
                    "threshold" = 0.3;
                    "strength" = 0.6;
                    "attack" = 0.2;
                    "release" = 0.5;
                    "gain (dB)" = 6.0;
                  };
                }
                {
                  # Subtle harmonic warmth/coloration
                  "type" = "ladspa";
                  "name" = "tube";
                  "plugin" = "tap_tubewarmth";
                  "label" = "tap_tubewarmth";
                  "control" = {
                    "Drive" = 3.0;
                    "Tape--Tube Blend" = 5.0;
                  };
                }
                {
                  # Brickwall peak control
                  "type" = "ladspa";
                  "name" = "limit";
                  "plugin" = "tap_limiter";
                  "label" = "tap_limiter";
                  "control" = {
                    "Limit Level [dB]" = -1.0;
                    "Output Volume [dB]" = 0.0;
                  };
                }
              ];
              "links" = [
                { "output" = "rnnoise:Output"; "input" = "hp:In"; }
                { "output" = "hp:Out"; "input" = "warmth_shelf:In"; }
                { "output" = "warmth_shelf:Out"; "input" = "mud_cut:In"; }
                { "output" = "mud_cut:Out"; "input" = "presence:In"; }
                { "output" = "presence:Out"; "input" = "air:In"; }
                { "output" = "air:Out"; "input" = "deess:Input"; }
                { "output" = "deess:Output"; "input" = "comp:in"; }
                { "output" = "comp:out"; "input" = "tube:Input"; }
                { "output" = "tube:Output"; "input" = "limit:Input"; }
              ];
            };
            "audio.position" = [ "MONO" ];
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

    wireplumber = {
      enable = true;
      package = pkgs.wireplumber;

      extraConfig."80-default-devices" = {
        "wireplumber.settings" = {
          "default.audio.sink" = "main-virtual-sink";
          "default.audio.source" = "main-virtual-source";
        };
      };

      extraConfig."90-app-volumes" = {
        "node.rules" = [
          {
            matches = [{ "application.process.binary" = ".Discord-wrapped"; }];
            actions = {
              update-props = {
                "node.volume" = 1.5;
              };
            };
          }
        ];
      };
    };
  };
}
