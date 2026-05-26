{ config, pkgs, lib, userConfig, ... }:

{
  programs.jujutsu = {
    enable = true;

    settings = {
      user = {
        name = userConfig.username or config.home.username;
        email = userConfig.userEmail;
      };

      ui = {
        editor = "nvim";
        diff-editor = ":builtin";
        diff-formatter = ":git";
        pager = "delta";
        paginate = "auto";
        color = "auto";
        default-command = [ "shortlog" ];
      };

      aliases = {
        shortlog = [ "log" "-n" "10" ];
        bc = [ "bookmark" "create" ];
        bs = [ "bookmark" "set" ];
        some = [ "util" "exec" "--" "sh" "-c" "jj git fetch && jj new master" ];
      };

      signing = lib.mkIf (userConfig.gpgKey != "") {
        behavior = "own";
        backend = "gpg";
        key = userConfig.gpgKey;
        backends.gpg.program = "${pkgs.gnupg}/bin/gpg";
      };

      merge-tools.delta = {
        program = "delta";
        merge-args = [ "--navigate" "--side-by-side" "--syntax-theme" "TwoDark" "--dark" ];
      };

      revsets = {
        immutable-heads = ''remote_bookmarks(exact:"main") | remote_bookmarks(exact:"master")'';
        log = "all()";
      };

      revset-aliases = {
        "immutable_heads()" = ''remote_bookmarks(exact:"main") | remote_bookmarks(exact:"master")'';
      };

      git = {
        auto-local-branch = true;
        fetch = [ "origin" ];
        push = "origin";
        auto-track-bookmarks = true;
      };

      remotes = {
        origin = {
          auto-track-bookmarks = "glob:*";
        };
      };
    };
  };
}
