{ config, pkgs, lib, ... }:

{
  programs.firefox = {
    enable = true;
    package = pkgs.firefox;

    # Configure Firefox profiles
    profiles = {
      default = {
        id = 0;
        name = "default";
        isDefault = true;

        # Configure search engines
        search = {
          default = "ddg";
          force = true;
          engines = {
            "google" = {
              metaData.hidden = true;
            };
            "bing" = {
              metaData.hidden = true;
            };
            "amazondotcom-us" = {
              metaData.hidden = true;
            };
            "ebay" = {
              metaData.hidden = true;
            };
            "wikipedia" = {
              metaData.hidden = true;
            };
          };
        };

        # Configure Firefox settings (about:config)
        settings = {
          # Disable search suggestions
          "browser.search.suggest.enabled" = false;
          "browser.urlbar.suggest.searches" = false;
          "browser.urlbar.suggest.quicksuggest.sponsored" = false;
          "browser.urlbar.suggest.quicksuggest.nonsponsored" = false;
          "browser.urlbar.trending.featureGate" = false;
          "browser.urlbar.suggest.trending" = false;
          "browser.urlbar.suggest.engines" = false;
          "browser.urlbar.suggest.topsites" = false;
          "browser.urlbar.suggest.history" = false;
          "browser.urlbar.suggest.bookmark" = false;
          "browser.urlbar.suggest.openpage" = false;
          "browser.urlbar.suggest.quickactions" = false;

          "keyword.enabled" = true;
          "browser.fixup.alternate.enabled" = true;

          # Privacy settings
          "privacy.trackingprotection.enabled" = true;
          "privacy.trackingprotection.socialtracking.enabled" = true;
          "privacy.trackingprotection.cryptomining.enabled" = true;
          "privacy.trackingprotection.fingerprinting.enabled" = true;

          # Block location requests
          "permissions.default.geo" = 2; # 0=always ask, 1=allow, 2=block

          # Block notification requests
          "permissions.default.desktop-notification" = 2; # 0=always ask, 1=allow, 2=block

          # Performance settings
          "gfx.webrender.all" = true;
          "media.ffmpeg.vaapi.enabled" = true;
          "media.hardware-video-decoding.force-enabled" = true;

          # UI customization
          "browser.tabs.inTitlebar" = 1;
          "browser.compactmode.show" = true;
          "browser.uidensity" = 1; # 0=normal, 1=compact, 2=touch

          # Scaling settings for HiDPI displays
          "layout.css.devPixelsPerPx" = "1.0"; # Override system DPI scaling (default is -1.0 for system)

          # Dark mode settings
          "browser.theme.content-theme" = 0; # 0=dark, 1=light, 2=system
          "browser.theme.toolbar-theme" = 0; # 0=dark, 1=light, 2=system
          "extensions.activeThemeID" = "firefox-compact-dark@mozilla.org"; # Use built-in dark theme
          "ui.systemUsesDarkTheme" = 1; # Tell websites system uses dark theme
          "layout.css.prefers-color-scheme.content-override" = 0; # 0=dark, 1=light, 2=system

          # Behavior settings
          "browser.startup.page" = 3; # 0=blank, 1=home, 2=last visited, 3=resume previous
          "browser.startup.homepage" = "https://start.duckduckgo.com";
          "browser.newtabpage.enabled" = false;
          "browser.newtabpage.activity-stream.showSponsored" = false;
          "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
          "browser.showQuitWarning" = false;
          "browser.warnOnQuit" = false;

          # Startup optimization settings
          "browser.sessionstore.restore_on_demand" = true; # Don't load all tabs at once
          "browser.sessionstore.restore_pinned_tabs_on_demand" = true; # Lazy load pinned tabs
          "browser.sessionstore.max_resumed_crashes" = 0; # Skip crash recovery checks

          # Linux-specific optimizations
          "accessibility.force_disabled" = 1; # Disable accessibility services if not needed

          # Disable all Firefox Home content
          "browser.newtabpage.activity-stream.feeds.topsites" = false;
          "browser.newtabpage.activity-stream.showSearch" = false;
          "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
          "browser.newtabpage.activity-stream.feeds.section.highlights" = false;
          "browser.newtabpage.activity-stream.section.highlights.includeBookmarks" = false;
          "browser.newtabpage.activity-stream.section.highlights.includeDownloads" = false;
          "browser.newtabpage.activity-stream.section.highlights.includeVisited" = false;
          "browser.newtabpage.activity-stream.showWeather" = false;
          "browser.newtabpage.activity-stream.feeds.weather" = false;
          "browser.newtabpage.activity-stream.system.showWeather" = false;
          "browser.newtabpage.activity-stream.feeds.snippets" = false;
          "browser.newtabpage.activity-stream.feeds.section.aboutprovider" = false;
          "browser.aboutHomeSnippets.updateUrl" = "";
          "browser.newtabpage.activity-stream.feeds.asrouterfeed" = false;
          "browser.newtabpage.activity-stream.showSponsoredCheckboxes" = false;

          # Developer settings
          "devtools.chrome.enabled" = true;
          "devtools.debugger.remote-enabled" = true;

          # Disable telemetry
          "datareporting.healthreport.uploadEnabled" = false;
          "datareporting.policy.dataSubmissionEnabled" = false;
          "toolkit.telemetry.unified" = false;
          "toolkit.telemetry.enabled" = false;
          "toolkit.telemetry.server" = "data:,";
          "toolkit.telemetry.archive.enabled" = false;
          "toolkit.telemetry.coverage.opt-out" = true;

          # Disable Pocket
          "extensions.pocket.enabled" = false;
          "browser.newtabpage.activity-stream.section.highlights.includePocket" = false;

          # Enable extensions by default
          "extensions.autoDisableScopes" = 0; # Don't auto-disable any extensions

          # Disable password manager
          "signon.rememberSignons" = false; # Disable saving passwords
          "signon.autofillForms" = false; # Disable autofilling login forms
          "signon.generation.enabled" = false; # Disable password generation
          "signon.management.page.breach-alerts.enabled" = false; # Disable breach alerts
          "signon.management.page.breachAlertUrl" = "";
        };

        # Install extensions
        extensions.packages = with pkgs.nur.repos.rycee.firefox-addons; [
          ublock-origin
          darkreader
          privacy-badger
          decentraleyes
        ];

        # User chrome CSS customization (optional)
        userChrome = ''
        '';

        userContent = ''
        '';
      };
    };

    # Configure policies (enterprise policies)
    policies = {
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      DisablePocket = true;
      DisableFirefoxAccounts = true;
      DisableFirefoxScreenshots = true;
      DisplayMenuBar = "default-off";
      SearchBar = "unified";

      # Configure default preferences for all profiles
      Preferences = {
        "browser.contentblocking.category" = {
          Value = "standard";
          Status = "unlocked";
        };
        "extensions.formautofill.creditCards.enabled" = {
          Value = false;
          Status = "locked";
        };
      };
    };
  };
}
