{ pkgs, inputs, ... }:

let
  system = pkgs.stdenv.hostPlatform.system;

  wallpaperProvider = inputs.elephant.packages.${system}.elephant-providers.overrideAttrs (_: {
    src = pkgs.runCommand "elephant-src-with-wallpaper" { } ''
      cp -r ${inputs.elephant}/. $out
      chmod -R u+w $out
      mkdir -p $out/internal/providers/wallpaper
      cp ${./elephant-wallpaper/setup.go} $out/internal/providers/wallpaper/setup.go
    '';

    buildPhase = ''
      runHook preBuild
      go build -buildmode=plugin -buildvcs=false -trimpath -o wallpaper.so ./internal/providers/wallpaper
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out/lib/elephant/providers
      cp wallpaper.so $out/lib/elephant/providers/
      runHook postInstall
    '';
  });
in

{
  xdg.configFile."elephant/providers/wallpaper.so" = {
    source = "${wallpaperProvider}/lib/elephant/providers/wallpaper.so";
  };

  programs.walker = {
    enable = true;
    runAsService = true;

    config = {
      theme = "onedark";
      keybinds = {
        next     = [ "Down" "ctrl j" ];
        previous = [ "Up"   "ctrl k" ];
      };
      providers.default = [ "desktopapplications" "calc" "files" ];
      providers.prefixes = [
        { prefix = ";"; provider = "providerlist"; }
        { prefix = ">"; provider = "runner"; }
        { prefix = "."; provider = "symbols"; }
        { prefix = "!"; provider = "todo"; }
        { prefix = "%"; provider = "bookmarks"; }
        { prefix = "="; provider = "calc"; }
        { prefix = "@"; provider = "websearch"; }
        { prefix = ":"; provider = "clipboard"; }
        { prefix = "$"; provider = "windows"; }
        { prefix = "find "; provider = "files"; }
      ];
      providers.actions.desktopapplications = [
        { action = "start"; default = true; bind = "Return"; }
        { action = "new_instance"; label = "new instance"; bind = "ctrl Return"; }
        { action = "new_instance:keep"; label = "new+next"; bind = "ctrl alt Return"; after = "KeepOpen"; }
        { action = "pin"; bind = "ctrl p"; after = "AsyncReload"; }
        { action = "unpin"; bind = "ctrl p"; after = "AsyncReload"; }
        { action = "pinup"; bind = "ctrl n"; after = "AsyncReload"; }
        { action = "pindown"; bind = "ctrl m"; after = "AsyncReload"; }
      ];
    };

    themes = {
      "onedark" = {
        layouts = {
          "item_wallpaper" = ''
            <?xml version="1.0" encoding="UTF-8"?>
            <interface>
              <requires lib="gtk" version="4.0"></requires>
              <object class="GtkBox" id="ItemBox">
                <style>
                  <class name="item-box"></class>
                </style>
                <property name="orientation">horizontal</property>
                <property name="spacing">12</property>
                <child>
                  <object class="GtkImage" id="ItemImage">
                    <style>
                      <class name="item-image"></class>
                    </style>
                    <property name="halign">start</property>
                    <property name="valign">center</property>
                  </object>
                </child>
                <child>
                  <object class="GtkLabel" id="ItemText">
                    <style>
                      <class name="item-text"></class>
                    </style>
                    <property name="ellipsize">end</property>
                    <property name="xalign">0</property>
                    <property name="valign">center</property>
                    <property name="hexpand">true</property>
                  </object>
                </child>
              </object>
            </interface>
          '';
        };
        style = ''
          * {
            font-family: "JetBrainsMono Nerd Font", monospace;
            font-size: 14px;
            font-weight: bold;
          }

          .box-wrapper {
            background-color: rgba(50, 55, 65, 0.97);
            border: 1px solid rgba(100, 110, 130, 0.5);
            border-radius: 8px;
            box-shadow: 0 2px 8px rgba(0, 0, 0, 0.4);
            padding: 8px;
          }

          .search-container {
            background-color: rgba(40, 44, 52, 0.98);
            border: 1px solid rgba(100, 110, 130, 0.5);
            border-radius: 24px;
            padding: 4px 16px;
            margin-bottom: 8px;
          }

          .input {
            color: #abb2bf;
            background: transparent;
            caret-color: #61afef;
            border-radius: 24px;
            outline: none;
            box-shadow: none;
          }

          .input:focus,
          .input:active {
            outline: none;
            box-shadow: none;
          }

          .search-container:focus-within {
            border-color: #61afef;
          }

          .list {
            background: transparent;
          }

          .item-box {
            border-radius: 8px;
            padding: 6px 12px;
            transition: all 200ms ease;
            color: #abb2bf;
          }

          .item-box:hover {
            background-color: rgba(97, 175, 239, 0.15);
          }

          .item-box.current {
            background-color: rgba(97, 175, 239, 0.2);
            border-left: 2px solid #61afef;
          }

          .item-text {
            color: #abb2bf;
            font-size: 14px;
          }

          .item-subtext {
            color: #5c6370;
            font-size: 12px;
          }

          .placeholder {
            color: #5c6370;
          }

          .wallpaper .item-image {
            -gtk-icon-size: 240px;
            min-width: 240px;
            min-height: 160px;
          }

          .wallpaper .item-box {
            padding: 6px 8px;
          }

          .wallpaper .item-text {
            font-size: 13px;
          }
        '';
      };
    };
  };
}
