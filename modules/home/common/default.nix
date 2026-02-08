{ config, pkgs, lib, ... }:

{
  imports = [
    ./bat.nix
    ./databases.nix
    ./firefox.nix
    ./fish.nix
    ./ghostty.nix
    ./git.nix
    ./hn-tui.nix
    ./jujutsu.nix
    ./lsd.nix
    ./mise.nix
    ./mysql.nix
    ./neovim.nix
    ./postgres.nix
    ./rabbitmq.nix
    ./redis.nix
    ./ruby.nix
    ./selene.nix
    ./shell-ai.nix
    ./starship.nix
    ./tmux.nix
    ./weechat.nix
  ];
}
