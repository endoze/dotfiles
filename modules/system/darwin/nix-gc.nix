{ ... }:

let
  nixBin = "/nix/var/nix/profiles/default/bin";
in
{
  # nix-darwin's nix.gc and nix.optimise assert nix.enable, which is off for
  # Determinate Nix, so the equivalent launchd jobs are defined directly.
  # Root only expires system and root profiles; user profiles are expired by
  # the matching home-manager agent in modules/home/darwin/nix-gc.nix.
  launchd.daemons.nix-gc.serviceConfig = {
    ProgramArguments = [ "${nixBin}/nix-collect-garbage" "--delete-older-than" "14d" ];
    StartCalendarInterval = [{ Weekday = 0; Hour = 3; Minute = 30; }];
  };

  launchd.daemons.nix-optimise.serviceConfig = {
    ProgramArguments = [ "${nixBin}/nix" "store" "optimise" ];
    StartCalendarInterval = [{ Weekday = 0; Hour = 4; Minute = 30; }];
  };
}
