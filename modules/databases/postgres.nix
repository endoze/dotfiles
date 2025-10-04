{ pkgs, config, lib, ... }:

let
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;

  postgresqlWithExtensions = pkgs.postgresql.withPackages (p: [
    p.pgvector
    p.postgis
  ]);
  postgresDataDir = "${config.home.homeDirectory}/.local/share/postgresql";
  postgresBin = "${postgresqlWithExtensions}/bin";
in
{
  options.programs.postgres = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Postgres server.";
    };

    runAtLoad = lib.mkOption {
      type = lib.types.bool;
      default = lib.mkDefault true;
      description = "Start Postgres at boot";
    };
  };

  config = lib.mkIf config.programs.postgres.enable {
    home.packages = [ postgresqlWithExtensions ];

    launchd.agents.postgres = lib.mkIf isDarwin {
      enable = true;
      config = {
        ProgramArguments = [
          "${postgresBin}/postgres"
          "-D"
          postgresDataDir
        ];
        RunAtLoad = config.programs.postgres.runAtLoad;
        KeepAlive = {
          Crashed = true;
          SuccessfulExit = false;
        };
      };
    };

    systemd.user.services.postgres = lib.mkIf isLinux {
      Unit = {
        Description = "PostgreSQL Server";
        After = [ "network.target" ];
      };
      Service = {
        Type = "notify";
        ExecStart = "${postgresBin}/postgres -D ${postgresDataDir}";
        Restart = "on-failure";
        RestartSec = "5s";
      };
      Install = {
        WantedBy = if config.programs.postgres.runAtLoad then [ "default.target" ] else [ ];
      };
    };

    home.activation.initPostgresDataDir = lib.hm.dag.entryAfter [ "writeBoundry" ] ''
      if [[ ! -d "${postgresDataDir}" ]]; then
        mkdir -p ${postgresDataDir}
        ${postgresBin}/initdb -D ${postgresDataDir}
      fi
    '';
  };
}
