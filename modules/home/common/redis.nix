{ pkgs, config, lib, ... }:

let
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;

  redisBin = "${pkgs.redis}/bin";
  redisDataDir = "${config.home.homeDirectory}/.local/share/redis";
in
{
  options.programs.redis = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Redis server.";
    };

    runAtLoad = lib.mkOption {
      type = lib.types.bool;
      default = lib.mkDefault false;
      description = "Start Redis at boot";
    };
  };

  config = lib.mkIf config.programs.redis.enable {
    home.packages = [ pkgs.redis ];

    home.file."${redisDataDir}/redis.conf".text = ''
      port 6379
      dir ${redisDataDir}
      save 900 1
      save 300 10
      save 60 10000
      dbfilename dump.rdb
      loglevel notice
      logfile ""
      protected-mode no
      appendonly no
    '';

    launchd.agents.redis = lib.mkIf isDarwin {
      enable = true;
      config = {
        ProgramArguments = [
          "${redisBin}/redis-server"
          "${redisDataDir}/redis.conf"
        ];
        RunAtLoad = config.programs.redis.runAtLoad;
        KeepAlive = {
          Crashed = true;
          SuccessfulExit = false;
        };
      };
    };

    systemd.user.services.redis = lib.mkIf isLinux {
      Unit = {
        Description = "Redis Server";
        After = [ "network.target" ];
      };
      Service = {
        Type = "notify";
        ExecStart = "${redisBin}/redis-server ${redisDataDir}/redis.conf";
        Restart = "on-failure";
        RestartSec = "5s";
      };
      Install = {
        WantedBy = if config.programs.redis.runAtLoad then [ "default.target" ] else [ ];
      };
    };

    home.activation.initRedisDataDir = lib.hm.dag.entryAfter [ "writeBoundry" ] ''
      if [[ ! -d "${redisDataDir}" ]]; then
        mkdir -p ${redisDataDir}
      fi
    '';
  };
}