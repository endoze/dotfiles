{ config, pkgs, lib, ... }:

{
  options.services.dnsmasq-resolver = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable DNS resolver configuration for dnsmasq.";
    };

    domain = lib.mkOption {
      type = lib.types.str;
      default = "test";
      description = "Domain to resolve to localhost (e.g., 'test' for .test domains)";
    };
  };

  config = lib.mkIf config.services.dnsmasq-resolver.enable {
    services.resolved = {
      enable = true;
      domains = [ "~${config.services.dnsmasq-resolver.domain}" ];
      extraConfig = ''
        [Resolve]
        DNS=127.0.0.1
        Domains=~${config.services.dnsmasq-resolver.domain}
      '';
    };

    services.dnsmasq = {
      enable = true;
      settings = {
        port = 53;
        listen-address = [ "127.0.0.1" ];
        bind-interfaces = true;
        address = "/.${config.services.dnsmasq-resolver.domain}/127.0.0.1";
      };
    };
  };
}
