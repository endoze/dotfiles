{ config, pkgs, lib, sourceRoot, userConfig, ... }:

{
  home.packages = with pkgs; [
    weechat
  ];

  sops = {
    age.keyFile = "${userConfig.homeDirectory}/.config/sops/age/keys.txt";
    defaultSopsFile = sourceRoot + "/secrets/shared.enc.yaml";

    secrets."soju-password" = { };

    templates."sec.conf" = {
      content = ''
        #
        # weechat -- sec.conf
        #
        # WARNING: It is NOT recommended to edit this file by hand,
        # especially if WeeChat is running.
        #
        # Use commands like /set or /fset to change settings in WeeChat.
        #
        # For more info, see: https://weechat.org/doc/weechat/quickstart/
        #

        [crypt]
        cipher = aes256
        hash_algo = sha256
        passphrase_command = ""
        salt = on

        [data]
        __passphrase__ = off
        soju_password = "${config.sops.placeholder."soju-password"}"
      '';
    };
  };

  xdg.configFile = {
    "weechat/alias.conf".source = config.lib.file.mkOutOfStoreSymlink "${userConfig.dotfilesPath}/config/weechat/alias.conf";
    "weechat/buflist.conf".source = config.lib.file.mkOutOfStoreSymlink "${userConfig.dotfilesPath}/config/weechat/buflist.conf";
    "weechat/fset.conf".source = config.lib.file.mkOutOfStoreSymlink "${userConfig.dotfilesPath}/config/weechat/fset.conf";
    "weechat/irc.conf".source = config.lib.file.mkOutOfStoreSymlink "${userConfig.dotfilesPath}/config/weechat/irc.conf";
    "weechat/plugins.conf".source = config.lib.file.mkOutOfStoreSymlink "${userConfig.dotfilesPath}/config/weechat/plugins.conf";
    "weechat/script.conf".source = config.lib.file.mkOutOfStoreSymlink "${userConfig.dotfilesPath}/config/weechat/script.conf";
    "weechat/trigger.conf".source = config.lib.file.mkOutOfStoreSymlink "${userConfig.dotfilesPath}/config/weechat/trigger.conf";
    "weechat/weechat.conf".source = config.lib.file.mkOutOfStoreSymlink "${userConfig.dotfilesPath}/config/weechat/weechat.conf";
    "weechat/sec.conf".source = config.lib.file.mkOutOfStoreSymlink config.sops.templates."sec.conf".path;
  };
}
