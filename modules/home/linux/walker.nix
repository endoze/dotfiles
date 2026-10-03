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
      theme = "glass";
      keybinds = {
        next     = [ "Down" "ctrl j" ];
        previous = [ "Up"   "ctrl k" ];
      };
      # Apps and calc only. Files stay behind the explicit "find " prefix below so
      # ordinary queries never surface random files.
      providers.default = [ "desktopapplications" "calc" ];
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

    # Glass launcher: one glass box high on the screen, magnifier +
    # large query row, accent-pill selection. Fixed palette shared with the eww
    # bar, power menu, shirase and monban (no wallust). Blur comes from the
    # Hyprland layer rule for the "walker" namespace in config/hypr/configs/window.lua.
    themes.glass = {
      # layout.xml: default walker layout with the box anchored near the top,
      # 680px wide, sized to content (at most ~7 rows), plus a magnifier icon before the entry.
      layouts.layout = ''
        <?xml version="1.0" encoding="UTF-8"?>
        <interface>
          <requires lib="gtk" version="4.0"></requires>
          <object class="GtkWindow" id="Window">
            <style>
              <class name="window"></class>
            </style>
            <property name="resizable">true</property>
            <property name="title">Walker</property>
            <child>
              <object class="GtkBox" id="BoxWrapper">
                <style>
                  <class name="box-wrapper"></class>
                </style>
                <property name="overflow">hidden</property>
                <property name="orientation">horizontal</property>
                <property name="valign">start</property>
                <property name="margin-top">230</property>
                <property name="halign">center</property>
                <property name="width-request">680</property>
                <child>
                  <object class="GtkBox" id="Box">
                    <style>
                      <class name="box"></class>
                    </style>
                    <property name="orientation">vertical</property>
                    <property name="hexpand-set">true</property>
                    <property name="hexpand">true</property>
                    <property name="spacing">10</property>
                    <child>
                      <object class="GtkBox" id="SearchContainer">
                        <style>
                          <class name="search-container"></class>
                        </style>
                        <property name="overflow">hidden</property>
                        <property name="orientation">horizontal</property>
                        <property name="halign">fill</property>
                        <property name="hexpand-set">true</property>
                        <property name="hexpand">true</property>
                        <child>
                          <object class="GtkImage">
                            <style><class name="search-icon"></class></style>
                            <property name="icon-name">system-search-symbolic</property>
                            <property name="valign">center</property>
                          </object>
                        </child>
                        <child>
                          <object class="GtkEntry" id="Input">
                            <style>
                              <class name="input"></class>
                            </style>
                            <property name="halign">fill</property>
                            <property name="hexpand-set">true</property>
                            <property name="hexpand">true</property>
                          </object>
                        </child>
                      </object>
                    </child>
                    <child>
                      <object class="GtkBox" id="ContentContainer">
                        <style>
                          <class name="content-container"></class>
                        </style>
                        <property name="orientation">horizontal</property>
                        <property name="spacing">10</property>
                        <child>
                          <object class="GtkLabel" id="ElephantHint">
                            <style>
                              <class name="elephant-hint"></class>
                            </style>
                            <property name="label">Waiting for elephant...</property>
                            <property name="hexpand">true</property>
                            <property name="vexpand">true</property>
                            <property name="visible">false</property>
                            <property name="valign">0.5</property>
                          </object>
                        </child>
                        <child>
                          <object class="GtkLabel" id="Placeholder">
                            <style>
                              <class name="placeholder"></class>
                            </style>
                            <property name="label">No Results</property>
                            <property name="hexpand">true</property>
                            <property name="vexpand">true</property>
                            <property name="valign">0.5</property>
                          </object>
                        </child>
                        <child>
                          <object class="GtkScrolledWindow" id="Scroll">
                            <style>
                              <class name="scroll"></class>
                            </style>
                            <property name="can_focus">false</property>
                            <property name="overlay-scrolling">true</property>
                            <property name="hexpand">true</property>
                            <property name="vexpand">true</property>
                            <property name="max-content-width">656</property>
                            <property name="min-content-width">656</property>
                            <property name="max-content-height">360</property>
                            <property name="propagate-natural-height">true</property>
                            <property name="propagate-natural-width">true</property>
                            <property name="hscrollbar-policy">automatic</property>
                            <property name="vscrollbar-policy">automatic</property>
                            <child>
                              <object class="GtkGridView" id="List">
                                <style>
                                  <class name="list"></class>
                                </style>
                                <property name="max_columns">1</property>
                                <property name="min_columns">1</property>
                                <property name="can_focus">false</property>
                              </object>
                            </child>
                          </object>
                        </child>
                        <child>
                          <object class="GtkBox" id="Preview">
                            <style>
                              <class name="preview"></class>
                            </style>
                          </object>
                        </child>
                      </object>
                    </child>
                    <child>
                      <object class="GtkBox" id="Keybinds">
                        <property name="hexpand">true</property>
                        <property name="margin-top">10</property>
                        <style>
                          <class name="keybinds"></class>
                        </style>
                        <child>
                          <object class="GtkBox" id="GlobalKeybinds">
                            <property name="spacing">10</property>
                            <style>
                              <class name="global-keybinds"></class>
                            </style>
                          </object>
                        </child>
                        <child>
                          <object class="GtkBox" id="ItemKeybinds">
                            <property name="hexpand">true</property>
                            <property name="halign">end</property>
                            <property name="spacing">10</property>
                            <style>
                              <class name="item-keybinds"></class>
                            </style>
                          </object>
                        </child>
                      </object>
                    </child>
                    <child>
                      <object class="GtkLabel" id="Error">
                        <style>
                          <class name="error"></class>
                        </style>
                        <property name="xalign">0</property>
                        <property name="visible">false</property>
                      </object>
                    </child>
                  </object>
                </child>
              </object>
            </child>
          </object>
        </interface>
      '';
      style = ''
        /* walker: glass launcher. Fixed palette, matched to the eww bar,
         * power menu, shirase and monban. Blur comes from the Hyprland layer rule for
         * the "walker" namespace (ignore_alpha 0.5 keeps the box-shadow unblurred). */
        @define-color fg #e5e6e7;
        @define-color fg-dim rgba(229, 230, 231, 0.6);
        @define-color glass-fill rgba(80, 86, 92, 0.68);
        @define-color glass-outline rgba(4, 5, 6, 0.65);
        @define-color glass-sep rgba(255, 255, 255, 0.12);
        @define-color accent #0a84ff;
        @define-color red #ff7b72;
        
        * {
          all: unset;
          font-family: "Inter", sans-serif;
          color: @fg;
        }
        
        scrollbar { opacity: 0; }
        
        .box-wrapper {
          background: @glass-fill;
          border: 1px solid @glass-outline;
          border-radius: 20px;
          box-shadow:
            inset 0 1px 0 rgba(255, 255, 255, 0.25),
            inset 0 -1px 0 rgba(255, 255, 255, 0.30),
            inset 1px 0 0 rgba(255, 255, 255, 0.10),
            inset -1px 0 0 rgba(255, 255, 255, 0.10),
            inset 0 3px 8px rgba(255, 255, 255, 0.05),
            0 12px 40px rgba(0, 0, 0, 0.35);
          padding: 8px 12px 10px 12px;
        }
        
        /* Search row: magnifier + large query text, no inner box */
        .search-container { padding: 6px 6px 8px 6px; }
        .search-icon { -gtk-icon-size: 22px; color: @fg-dim; margin-right: 12px; }
        .input {
          font-size: 24px;
          font-weight: 400;
          padding: 6px 0;
          caret-color: @fg;
        }
        .input placeholder { color: @fg-dim; }
        .input selection { background: alpha(@accent, 0.45); }
        
        /* Results */
        .content-container {
          border-top: 1px solid @glass-sep;
          padding-top: 8px;
        }
        .placeholder, .elephant-hint { color: @fg-dim; font-size: 15px; padding: 14px; }
        .list { color: @fg; }
        .normal-icons { -gtk-icon-size: 30px; }
        .large-icons { -gtk-icon-size: 36px; }
        .item-image-text { font-size: 26px; }
        .item-box {
          padding: 8px 12px;
          border-radius: 11px;
          transition: background 100ms ease;
        }
        child:hover .item-box { background: rgba(255, 255, 255, 0.08); }
        child:selected .item-box,
        row:selected .item-box { background: alpha(@accent, 0.78); }
        .item-text { font-size: 15px; font-weight: 500; }
        .item-subtext { font-size: 13px; color: @fg-dim; }
        child:selected .item-subtext,
        row:selected .item-subtext { color: rgba(255, 255, 255, 0.8); }
        .providerlist .item-subtext { font-size: 13px; }
        .item-quick-activation {
          font-size: 12px;
          font-weight: 600;
          color: @fg-dim;
          background: rgba(255, 255, 255, 0.10);
          border-radius: 6px;
          padding: 2px 7px;
        }
        child:selected .item-quick-activation,
        row:selected .item-quick-activation { color: #ffffff; background: rgba(255, 255, 255, 0.22); }
        
        .calc .item-text { font-size: 22px; }
        .symbols .item-image { font-size: 22px; }
        .todo.done .item-text-box { opacity: 0.35; }
        .todo.urgent { font-size: 18px; }
        .todo.active { font-weight: 600; }
        .bluetooth.disconnected { opacity: 0.5; }
        
        .preview {
          border: 1px solid @glass-sep;
          border-radius: 12px;
          padding: 8px;
        }
        .preview .large-icons { -gtk-icon-size: 64px; }
        
        /* Keybind hints */
        .keybinds {
          margin-top: 6px;
          padding-top: 8px;
          border-top: 1px solid @glass-sep;
          font-size: 12px;
          color: @fg-dim;
        }
        .keybind-button { opacity: 0.7; }
        .keybind-button:hover { opacity: 1; }
        .keybind-bind { text-transform: lowercase; color: @fg-dim; }
        .keybind-label {
          padding: 1px 6px;
          border-radius: 5px;
          background: rgba(255, 255, 255, 0.12);
          color: @fg;
        }
        
        /* Action menu popover: same glass as the power menu */
        popover {
          background: rgba(80, 86, 92, 0.9);
          border: 1px solid @glass-outline;
          border-radius: 15px;
          box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.25), 0 4px 24px rgba(0, 0, 0, 0.30);
          padding: 6px;
        }
        popover row, popover .item-box { border-radius: 9px; padding: 7px 14px; }
        popover row:selected, popover child:selected .item-box { background: alpha(@accent, 0.78); }
        
        .error { color: @red; font-size: 13px; }
      '';
    };
  };
}
