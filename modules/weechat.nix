{ config, pkgs, lib, sourceRoot, userConfig, ... }:

{
  home.packages = with pkgs; [
    weechat
  ];

  xdg.configFile = {
    "weechat/alias.conf".source = config.lib.file.mkOutOfStoreSymlink "${userConfig.dotfilesPath}/config/weechat/alias.conf";
    "weechat/buflist.conf".source = config.lib.file.mkOutOfStoreSymlink "${userConfig.dotfilesPath}/config/weechat/buflist.conf";
    "weechat/fset.conf".source = config.lib.file.mkOutOfStoreSymlink "${userConfig.dotfilesPath}/config/weechat/fset.conf";
    "weechat/irc.conf".source = config.lib.file.mkOutOfStoreSymlink "${userConfig.dotfilesPath}/config/weechat/irc.conf";
    "weechat/plugins.conf".source = config.lib.file.mkOutOfStoreSymlink "${userConfig.dotfilesPath}/config/weechat/plugins.conf";
    "weechat/script.conf".source = config.lib.file.mkOutOfStoreSymlink "${userConfig.dotfilesPath}/config/weechat/script.conf";
    "weechat/trigger.conf".source = config.lib.file.mkOutOfStoreSymlink "${userConfig.dotfilesPath}/config/weechat/trigger.conf";
    "weechat/weechat.conf".source = config.lib.file.mkOutOfStoreSymlink "${userConfig.dotfilesPath}/config/weechat/weechat.conf";
  };
}
