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

  home.file.".local/share/applications/ungoogled-chromium.desktop".text = ''
    [Desktop Entry]
    Name=Ungoogled Chromium
    GenericName=Web Browser
    Comment=Access the Internet
    Exec=chromium %U
    StartupNotify=true
    Terminal=false
    Icon=chromium
    Type=Application
    Categories=Network;WebBrowser;
    MimeType=x-scheme-handler/chromium;
    StartupWMClass=chromium-browser
    Actions=new-window;new-private-window;

    [Desktop Action new-window]
    Name=New Window
    Exec=chromium

    [Desktop Action new-private-window]
    Name=New Incognito Window
    Exec=chromium --incognito
  '';
}
