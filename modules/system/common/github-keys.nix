{ pkgs, lib, userConfig ? { }, ... }:

let
  githubUser = userConfig.username;
  publicKeysFile = builtins.readFile (pkgs.fetchurl {
    url = "https://github.com/${githubUser}.keys";
    sha256 = "iCQsSHJ2IYC7bXb7v/ifYJHcV3W3OiLnshr0bF4RcoY=";
  });
  publicKeys = lib.splitString "\n" (lib.removeSuffix "\n" publicKeysFile);
in
{
  users.users."${userConfig.username}" = {
    openssh.authorizedKeys.keys = publicKeys;
  };
}
