{ pkgs, inputs, ... }:

# Hand-rolled walker wallpaper picker replaced by waypaper (modules/home/linux/waypaper.nix).
# Keeping the wiring below commented out for reference / easy revert.
#
# let
#   system = pkgs.stdenv.hostPlatform.system;
#
#   wallpaperProvider = inputs.elephant.packages.${system}.elephant-providers.overrideAttrs (_: {
#     src = pkgs.runCommand "elephant-src-with-wallpaper" { } ''
#       cp -r ${inputs.elephant}/. $out
#       chmod -R u+w $out
#       mkdir -p $out/internal/providers/wallpaper
#       cp ${./elephant-wallpaper/setup.go} $out/internal/providers/wallpaper/setup.go
#     '';
#
#     buildPhase = ''
#       runHook preBuild
#       go build -buildmode=plugin -buildvcs=false -trimpath -o wallpaper.so ./internal/providers/wallpaper
#       runHook postBuild
#     '';
#
#     installPhase = ''
#       runHook preInstall
#       mkdir -p $out/lib/elephant/providers
#       cp wallpaper.so $out/lib/elephant/providers/
#       runHook postInstall
#     '';
#   });
# in

{
  # xdg.configFile."elephant/providers/wallpaper.so" = {
  #   source = "${wallpaperProvider}/lib/elephant/providers/wallpaper.so";
  # };

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
        # Wallpaper layout retired with the hand-rolled walker picker;
        # waypaper handles wallpaper selection now.
        layouts = {
          # "item_wallpaper" = ''
          #   <?xml version="1.0" encoding="UTF-8"?>
          #   <interface>
          #     <requires lib="gtk" version="4.0"></requires>
          #     <object class="GtkBox" id="ItemBox">
          #       <style>
          #         <class name="item-box"></class>
          #       </style>
          #       <property name="orientation">horizontal</property>
          #       <property name="spacing">12</property>
          #       <child>
          #         <object class="GtkImage" id="ItemImage">
          #           <style>
          #             <class name="item-image"></class>
          #           </style>
          #           <property name="halign">start</property>
          #           <property name="valign">center</property>
          #         </object>
          #       </child>
          #       <child>
          #         <object class="GtkLabel" id="ItemText">
          #           <style>
          #             <class name="item-text"></class>
          #           </style>
          #           <property name="ellipsize">end</property>
          #           <property name="xalign">0</property>
          #           <property name="valign">center</property>
          #           <property name="hexpand">true</property>
          #         </object>
          #       </child>
          #     </object>
          #   </interface>
          # '';
        };
        style = ''
          /* Colors come from wallust via the import below, seeded with a One Dark
             fallback on first run and regenerated per wallpaper. walker has no CSS
             watcher, so wallust-apply restarts the service to pick up changes. */
          @import url("file:///home/endoze/.cache/wallust/walker-colors.css");

          * {
            font-family: "JetBrainsMono Nerd Font", monospace;
            font-size: 14px;
            font-weight: bold;
          }

          .box-wrapper {
            background-color: alpha(@background, 0.97);
            border: 1px solid alpha(@border, 0.5);
            border-radius: 8px;
            box-shadow: 0 2px 8px rgba(0, 0, 0, 0.4);
            padding: 8px;
          }

          .search-container {
            background-color: alpha(@background, 0.98);
            border: 1px solid alpha(@border, 0.5);
            border-radius: 24px;
            padding: 4px 16px;
            margin-bottom: 8px;
          }

          .input {
            color: @foreground;
            background: transparent;
            caret-color: @accent;
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
            border-color: @accent;
          }

          .list {
            background: transparent;
          }

          .item-box {
            border-radius: 8px;
            padding: 6px 12px;
            transition: all 200ms ease;
            color: @foreground;
          }

          .item-box:hover {
            background-color: alpha(@accent, 0.15);
          }

          .item-box.current {
            background-color: alpha(@accent, 0.2);
            border-left: 2px solid @accent;
          }

          .item-text {
            color: @foreground;
            font-size: 14px;
          }

          .item-subtext {
            color: @fg-dim;
            font-size: 12px;
          }

          .placeholder {
            color: @fg-dim;
          }

          /* Wallpaper picker styles retired with the hand-rolled walker provider;
             waypaper handles its own UI now.

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
          */
        '';
      };
    };
  };
}
