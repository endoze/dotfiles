{ config, pkgs, lib, ... }:

{
  programs.chromium = {
    enable = true;
    package = pkgs.ungoogled-chromium;

    extensions = [
      {
        # chromium-web-store - enables installing extensions from Chrome Web Store
        id = "ocaahdebbfolfmndjeplogmgcagdmblk";
        updateUrl = "https://raw.githubusercontent.com/NeverDecaf/chromium-web-store/master/updates.xml";
      }
    ];

    commandLineArgs = [
      "--extension-mime-request-handling=always-prompt-for-install"
    ];
  };
}
