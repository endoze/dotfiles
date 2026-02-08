{ pkgs, config, lib, systemConfig, ... }:

let
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;

  rabbitmqBin = "${pkgs.rabbitmq-server}/bin";
  rabbitmqDataDir = "${config.home.homeDirectory}/.local/share/rabbitmq";
  rabbitmqNodename = "rabbit@${systemConfig.hostName}";
in
{
  options.programs.rabbitmq = {
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

  config = lib.mkIf config.programs.rabbitmq.enable {
    home.packages = [ pkgs.rabbitmq-server ];

    home.file."${rabbitmqDataDir}/rabbitmq-env.conf".text = ''
      CONFIG_FILE=${rabbitmqDataDir}/rabbitmq.conf
      BASE=${rabbitmqDataDir}
      LOG_BASE=${rabbitmqDataDir}/logs
      NODENAME=${rabbitmqNodename}
      MNESIA_BASE=${rabbitmqDataDir}/mnesia
      MNESIA_DIR=${rabbitmqDataDir}/mnesia/${rabbitmqNodename}
      ENABLED_PLUGINS_FILE=${rabbitmqDataDir}/enabled_plugins
      PLUGINS_DIR=${pkgs.rabbitmq-server}/plugins
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
          RABBITMQ_PLUGINS_DIR = "${pkgs.rabbitmq-server}/plugins";
          RABBITMQ_PLUGINS_EXPAND_DIR = "${rabbitmqDataDir}/mnesia/${rabbitmqNodename}-plugins-expand";
          RABBITMQ_MNESIA_BASE = "${rabbitmqDataDir}/mnesia";
          RABBITMQ_MNESIA_DIR = "${rabbitmqDataDir}/mnesia/${rabbitmqNodename}";
          RABBITMQ_LOG_BASE = "${rabbitmqDataDir}/logs";
          RABBITMQ_NODENAME = "${rabbitmqNodename}";
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
        Type = "simple";
        ExecStart = "${rabbitmqBin}/rabbitmq-server";
        Restart = "on-failure";
        RestartSec = "5s";
        StandardError = "append:${rabbitmqDataDir}/logs/std_error.log";
        StandardOutput = "append:${rabbitmqDataDir}/logs/std_out.log";
        Environment = [
          "RABBITMQ_CONF_ENV_FILE=${rabbitmqDataDir}/rabbitmq-env.conf"
          "RABBITMQ_HOME=${rabbitmqDataDir}"
          "RABBITMQ_ENABLED_PLUGINS_FILE=${rabbitmqDataDir}/enabled_plugins"
          "RABBITMQ_PLUGINS_DIR=${pkgs.rabbitmq-server}/plugins"
          "RABBITMQ_PLUGINS_EXPAND_DIR=${rabbitmqDataDir}/mnesia/${rabbitmqNodename}-plugins-expand"
          "RABBITMQ_MNESIA_BASE=${rabbitmqDataDir}/mnesia"
          "RABBITMQ_MNESIA_DIR=${rabbitmqDataDir}/mnesia/${rabbitmqNodename}"
          "RABBITMQ_LOG_BASE=${rabbitmqDataDir}/logs"
          "RABBITMQ_NODENAME=${rabbitmqNodename}"
        ];
      };
      Install = {
        WantedBy = if config.programs.rabbitmq.runAtLoad then [ "default.target" ] else [ ];
      };
    };

    home.activation.initRabbitMQDataDir = lib.hm.dag.entryAfter [ "writeBoundry" ] ''
      if [[ ! -d "${rabbitmqDataDir}" ]]; then
        mkdir -p ${rabbitmqDataDir}
        mkdir -p ${rabbitmqDataDir}/logs
        mkdir -p ${rabbitmqDataDir}/mnesia
        mkdir -p ${rabbitmqDataDir}/pids
      fi
      # Ensure the plugins-expand directory exists
      mkdir -p ${rabbitmqDataDir}/mnesia/${rabbitmqNodename}-plugins-expand
    '';
  };
}