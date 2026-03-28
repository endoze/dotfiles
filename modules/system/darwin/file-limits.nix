{ ... }:

{
  launchd.daemons.maxfiles = {
    serviceConfig = {
      Label = "org.nixos.maxfiles";
      ProgramArguments = [
        "launchctl"
        "limit"
        "maxfiles"
        "524288"
        "524288"
      ];
      RunAtLoad = true;
    };
  };

  launchd.daemons.maxproc = {
    serviceConfig = {
      Label = "org.nixos.maxproc";
      ProgramArguments = [
        "launchctl"
        "limit"
        "maxproc"
        "10000"
        "10000"
      ];
      RunAtLoad = true;
    };
  };
}
