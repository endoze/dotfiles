{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    _1password-cli
  ];

  home.sessionVariables = {
    DEVELOPMENT_MACHINE = "macbook";
  };

  programs.mysql.enable = true;
  programs.redis.enable = true;
  programs.rabbitmq.enable = true;
  programs.postgres.enable = true;
}
