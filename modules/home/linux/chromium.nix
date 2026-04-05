{ config, pkgs, lib, ... }:

{
  programs.chromium = {
    enable = true;
    package = pkgs.ungoogled-chromium.override {
      enableWideVine = true;
    };

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

  home.file.".local/share/applications/apple-music.desktop".text = ''
    [Desktop Entry]
    Version=1.0
    Terminal=false
    Type=Application
    Name=Apple Music
    Exec=chromium --user-data-dir=${config.home.homeDirectory}/.config/chromium-apple-music --app=https://music.apple.com
    Icon=chrome-blgdilankhbcpipclgpdndahbehalgkh-Default
    StartupWMClass=chromium-browser
    Categories=Audio;Music;
  '';
}
