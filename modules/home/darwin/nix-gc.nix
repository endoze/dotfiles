{ ... }:

{
  # home-manager's nix.gc passes `options` as a single argv entry, which
  # nix-collect-garbage rejects, so the agent is defined directly. Runs
  # before the system daemon in modules/system/darwin/nix-gc.nix.
  launchd.agents.nix-gc = {
    enable = true;
    config = {
      ProgramArguments = [
        "/nix/var/nix/profiles/default/bin/nix-collect-garbage"
        "--delete-older-than"
        "14d"
      ];
      StartCalendarInterval = [{ Weekday = 0; Hour = 3; Minute = 0; }];
    };
  };
}
