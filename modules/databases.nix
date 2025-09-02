{ pkgs, unstable, config, lib, systemConfig, ... }:

let
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;

  postgresqlWithExtensions = pkgs.postgresql.withPackages (p: [ p.pgvector ]);
  postgresDataDir = "${config.home.homeDirectory}/.local/share/postgresql";
  postgresBin = "${postgresqlWithExtensions}/bin";
  mysqlBaseDir = "${config.home.homeDirectory}/.local/share/mysql";
  mysqlDataDir = "${mysqlBaseDir}/data";
  mysqlBin = "${pkgs.mysql84}/bin";
  mysqlSocketPath = if isDarwin then "/tmp/mysql.sock" else "/run/user/\${UID}/mysql.sock";
  mysqlxSocketPath = if isDarwin then "/tmp/mysqlx.sock" else "/run/user/\${UID}/mysqlx.sock";
  redisBin = "${pkgs.redis}/bin";
  redisDataDir = "${config.home.homeDirectory}/.local/share/redis";
  rabbitmqBin = "${unstable.rabbitmq-server}/bin";
  rabbitmqDataDir = "${config.home.homeDirectory}/.local/share/rabbitmq";
  rabbitmqNodename = "rabbit@${systemConfig.hostName}";
in
{
  options.programs = {
    mysql = {
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

    postgres = {
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

    rabbitmq = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable RabbitMQ server.";
      };

      runAtLoad = lib.mkOption {
        type = lib.types.bool;
        default = lib.mkDefault false;
        description = "Start RabbitMQ at boot";
      };
    };

    redis = {
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
  };

  config = lib.mkMerge [
    (lib.mkIf config.programs.mysql.enable {
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
    })
    (lib.mkIf config.programs.postgres.enable {
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
    })
    (lib.mkIf config.programs.rabbitmq.enable {
      home.packages = [ unstable.rabbitmq-server ];

      home.file."${rabbitmqDataDir}/rabbitmq-env.conf".text = ''
        CONFIG_FILE=${rabbitmqDataDir}/rabbitmq.conf
        BASE=${rabbitmqDataDir}
        LOG_BASE=${rabbitmqDataDir}/logs
        NODENAME=${rabbitmqNodename}
        MNESIA_DIR=${rabbitmqDataDir}/mnesia
        ENABLED_PLUGINS_FILE=${rabbitmqDataDir}/enabled_plugins
        PLUGINS_DIR=${unstable.rabbitmq-server}/plugins
        PLUGINS_EXPAND_DIR=${rabbitmqDataDir}/mnesia/${rabbitmqNodename}-plugins-expand
        PID_FILE=${rabbitmqDataDir}/pids/rabbitmq-server.pid
      '';

      home.file."${rabbitmqDataDir}/rabbitmq.conf".text = ''
        listeners.tcp.default = 5672

        management.tcp.port = 15672
        management.tcp.ip   = 0.0.0.0

        log.dir = ${rabbitmqDataDir}/logs

        default_user = guest
        default_pass = guest
        default_permissions.configure = .*
        default_permissions.read = .*
        default_permissions.write = .*
      '';

      home.file."${rabbitmqDataDir}/enabled_plugins".text = ''
        [rabbitmq_management,rabbitmq_stomp,rabbitmq_amqp1_0,rabbitmq_mqtt,rabbitmq_stream,rabbitmq_management_agent,rabbitmq_web_dispatch].
      '';

      launchd.agents.rabbitmq = lib.mkIf isDarwin {
        enable = true;
        config = {
          ProgramArguments = [
            "${rabbitmqBin}/rabbitmq-server"
          ];
          EnvironmentVariables = {
            RABBITMQ_CONF_ENV_FILE = "${rabbitmqDataDir}/rabbitmq-env.conf";
            RABBITMQ_HOME = "${rabbitmqDataDir}";
            RABBITMQ_ENABLED_PLUGINS_FILE = "${rabbitmqDataDir}/enabled_plugins";
            RABBITMQ_PLUGINS_DIR = "${unstable.rabbitmq-server}/plugins";
            RABBITMQ_PLUGINS_EXPAND_DIR = "${rabbitmqDataDir}/mnesia/${rabbitmqNodename}-plugins-expand";
          };
          StandardErrorPath = "${rabbitmqDataDir}/logs/std_error.log";
          StandardOutPath = "${rabbitmqDataDir}/logs/std_out.log";
          RunAtLoad = config.programs.rabbitmq.runAtLoad;
          KeepAlive = {
            Crashed = true;
            SuccessfulExit = false;
          };
        };
      };

      systemd.user.services.rabbitmq = lib.mkIf isLinux {
        Unit = {
          Description = "RabbitMQ Server";
          After = [ "network.target" ];
        };
        Service = {
          Type = "notify";
          ExecStart = "${rabbitmqBin}/rabbitmq-server";
          Restart = "on-failure";
          RestartSec = "5s";
          Environment = [
            "RABBITMQ_CONF_ENV_FILE=${rabbitmqDataDir}/rabbitmq-env.conf"
            "RABBITMQ_HOME=${rabbitmqDataDir}"
            "RABBITMQ_ENABLED_PLUGINS_FILE=${rabbitmqDataDir}/enabled_plugins"
            "RABBITMQ_PLUGINS_DIR=${unstable.rabbitmq-server}/plugins"
            "RABBITMQ_PLUGINS_EXPAND_DIR=${rabbitmqDataDir}/mnesia/${rabbitmqNodename}-plugins-expand"
          ];
        };
        Install = {
          WantedBy = if config.programs.rabbitmq.runAtLoad then [ "default.target" ] else [ ];
        };
      };

      home.activation.initRabbitMQDataDir = lib.hm.dag.entryAfter [ "writeBoundry" ] ''
        if [[ ! -d "${rabbitmqDataDir}" ]]; then
          mkdir -p ${rabbitmqDataDir}
          mkdir ${rabbitmqDataDir}/logs
          mkdir ${rabbitmqDataDir}/mnesia
          mkdir ${rabbitmqDataDir}/pids
        fi
      '';
    })
    (lib.mkIf config.programs.redis.enable {

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
    })
  ];
}
