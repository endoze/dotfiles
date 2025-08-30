{ sourceRoot ? ./.. }:
let
  # Try to read local config, fall back to defaults
  # When running with --impure, we can read from the actual filesystem
  # Handle both sudo (SUDO_USER) and non-sudo (HOME) scenarios
  sudoUser = builtins.getEnv "SUDO_USER";
  homeDir =
    if sudoUser != ""
    then "/Users/${sudoUser}"
    else builtins.getEnv "HOME";

  localConfigPath =
    if homeDir != ""
    then /. + homeDir + "/.dotfiles/modules/users.local.nix"
    else sourceRoot + "/modules/users.local.nix";

  config =
    if builtins.pathExists localConfigPath
    then import localConfigPath
    else {
      username = "user";
      fullName = "Default User";
      userEmail = "user@example.com";
      gpgKey = "";
      hostName = "nixos";
      computerName = "Nix Computer";
    };
in
{
  inherit config;

  getUserConfig = { system }:
    let
      homeBase =
        if builtins.elem system [ "aarch64-darwin" "x86_64-darwin" ]
        then "/Users"
        else "/home";
    in
    {
      username = config.username;
      fullName = config.fullName;
      userEmail = config.userEmail;
      gpgKey = config.gpgKey or "";
      homeDirectory = "${homeBase}/${config.username}";
    };

  getSystemConfig = {
    hostName = config.hostName;
    computerName = config.computerName or config.hostName;
  };
}
