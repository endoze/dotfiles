{ pkgs, config, lib, ... }:

let
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;

  mysqlBaseDir = "${config.home.homeDirectory}/.local/share/mysql";
  mysqlDataDir = "${mysqlBaseDir}/data";
  mysqlBin = "${pkgs.mysql84}/bin";
  mysqlSocketPath = if isDarwin then "/tmp/mysql.sock" else "/run/user/\${UID}/mysql.sock";
  mysqlxSocketPath = if isDarwin then "/tmp/mysqlx.sock" else "/run/user/\${UID}/mysqlx.sock";
in
{
  options.programs.mysql = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable MySQL server.";
    };

    runAtLoad = lib.mkOption {
      type = lib.types.bool;
      default = lib.mkDefault true;
      description = "Start MySQL at boot";
    };
  };

  config = lib.mkIf config.programs.mysql.enable {
    home.packages = [ pkgs.mysql84 ];

    home.file.".my.cnf".text = ''
      [mysqld]
      socket=${mysqlSocketPath}
      bind-address = 0.0.0.0
      port = 3306
      mysqlx_socket=${mysqlxSocketPath}
      disable_log_bin
      character-set-server = utf8mb4
      collation-server = utf8mb4_unicode_ci
      [client]
      socket=${mysqlSocketPath}
    '';

    launchd.agents.mysql = lib.mkIf isDarwin {
      enable = true;
      config = {
        ProgramArguments = [
          "${mysqlBin}/mysqld"
          "--basedir=${pkgs.mysql84}"
          "--datadir=${mysqlDataDir}"
          "--log-error=${mysqlBaseDir}/mysqld.local.err"
          "--pid-file=${mysqlBaseDir}/mysqld.local.pid"
        ];
        RunAtLoad = config.programs.mysql.runAtLoad;
        KeepAlive = {
          Crashed = true;
          SuccessfulExit = false;
        };
        WorkingDirectory = mysqlBaseDir;
      };
    };

    systemd.user.services.mysql = lib.mkIf isLinux {
      Unit = {
        Description = "MySQL Server";
        After = [ "network.target" ];
      };
      Service = {
        Type = "notify";
        ExecStart = "${mysqlBin}/mysqld --basedir=${pkgs.mysql84} --datadir=${mysqlDataDir} --log-error=${mysqlBaseDir}/mysqld.local.err --pid-file=${mysqlBaseDir}/mysqld.local.pid";
        Restart = "on-failure";
        RestartSec = "5s";
        WorkingDirectory = mysqlBaseDir;
      };
      Install = {
        WantedBy = if config.programs.mysql.runAtLoad then [ "default.target" ] else [ ];
      };
    };

    home.activation.initMysqlDataDir = lib.hm.dag.entryAfter [ "writeBoundry" ] ''
      if [[ ! -d "${mysqlDataDir}" ]]; then
        mkdir -p ${mysqlDataDir}
        ${mysqlBin}/mysqld --initialize-insecure --datadir=${mysqlDataDir}
      fi
    '';
  };
}