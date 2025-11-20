{ config, pkgs, lib, ... }:

let
  cfg = config.services.dnsmasq-resolver;
  dnsmasqConfigFile = pkgs.writeText "dnsmasq.conf" ''
    port=53
    listen-address=127.0.0.1
    bind-interfaces
    address=/.${cfg.domain}/127.0.0.1
    no-resolv
    no-poll
    server=1.1.1.1
    server=1.0.0.1
  '';
in
{
  options.services.dnsmasq-resolver = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable dnsmasq DNS resolver for local development domains.";
    };

    domain = lib.mkOption {
      type = lib.types.str;
      default = "test";
      description = "Domain to resolve to localhost (e.g., 'test' for .test domains)";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.dnsmasq ];

    environment.etc."resolver/${cfg.domain}".text = ''
      nameserver 127.0.0.1
    '';

    launchd.daemons.dnsmasq = {
      serviceConfig = {
        Label = "org.nixos.dnsmasq";
        ProgramArguments = [
          "${pkgs.dnsmasq}/bin/dnsmasq"
          "--keep-in-foreground"
          "--conf-file=${dnsmasqConfigFile}"
        ];
        RunAtLoad = true;
        KeepAlive = {
          Crashed = true;
          SuccessfulExit = false;
        };
        StandardOutPath = "/var/log/dnsmasq.log";
        StandardErrorPath = "/var/log/dnsmasq.error.log";
      };
    };
  };
}
