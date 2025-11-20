{ pkgs, ... }:

{
  # Gnome-keyring is now handled by system PAM configuration
  # Point SSH_AUTH_SOCK to the gcr-ssh-agent socket location
  home.sessionVariables = {
    SSH_AUTH_SOCK = "/run/user/1000/gcr/ssh";
  };
}
