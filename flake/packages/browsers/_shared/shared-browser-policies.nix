{lib, ...}: {
  extensions ? {},
  prefs ? {},
  policies ? {},
  ...
}: let
  extension = shortId: guid: {
    name = guid;
    value = {
      install_url = "https://addons.mozilla.org/en-US/firefox/downloads/latest/${shortId}/latest.xpi";
      installation_mode = "normal_installed";
    };
  };

  common-prefs = {
    # Hide the warning screen when opening about:config.
    "browser.aboutConfig.showWarning" = false;
    # Make Ctrl+Tab cycle through tabs in most-recently-used order.
    "browser.ctrlTab.sortByRecentlyUsed" = true;
    # Restore the previous session on startup: previous windows and tabs.
    "browser.startup.page" = 3;
    # Disable the built-in password manager prompt.
    "signon.rememberSignons" = false;
    # Disable search suggestions globally.
    "browser.search.suggest.enabled" = false;
    # Disable search suggestions in Private Browsing windows.
    "browser.search.suggest.enabled.private" = false;
    # Disable search-engine suggestions in the address bar.
    "browser.urlbar.suggest.searches" = false;
    # Disable sponsored Firefox Suggest / address-bar suggestions.
    "browser.urlbar.suggest.quicksuggest.sponsored" = false;
    "browser.urlbar.suggest.quicksuggest.nonsponsored" = false;
    # Disable address-bar suggestions from browsing history.
    # Optional: keep this true if you like history autocomplete.
    "browser.urlbar.suggest.history" = false;
    # Disable address-bar suggestions from bookmarks.
    # Optional: keep this true if you like bookmark autocomplete.
    "browser.urlbar.suggest.bookmark" = false;
    # Disable address-bar suggestions from open tabs.
    # Optional: keep this true if you like tab switching from the URL bar.
    "browser.urlbar.suggest.openpage" = false;
    # Disable Pocket integration.
    "extensions.pocket.enabled" = false;
    # Disable studies/experiments.
    "app.shield.optoutstudies.enabled" = false;
    # Disable Mozilla telemetry upload.
    # Mozilla describes telemetry as technical and interaction data used to improve Firefox.
    "datareporting.healthreport.uploadEnabled" = false;
    "datareporting.policy.dataSubmissionEnabled" = false;
    "toolkit.telemetry.enabled" = false;
    "toolkit.telemetry.unified" = false;
    "toolkit.telemetry.archive.enabled" = false;
    "toolkit.telemetry.newProfilePing.enabled" = false;
    "toolkit.telemetry.shutdownPingSender.enabled" = false;
    "toolkit.telemetry.updatePing.enabled" = false;
    "toolkit.telemetry.bhrPing.enabled" = false;
    "toolkit.telemetry.firstShutdownPing.enabled" = false;
    # Disable Firefox/Zen crash report submission.
    "breakpad.reportURL" = "";
    "browser.tabs.crashReporting.sendReport" = false;
    # Disable “new tab” sponsored/top-site content.
    "browser.newtabpage.activity-stream.showSponsored" = false;
    "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
    "browser.newtabpage.activity-stream.feeds.topsites" = false;
    "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
    # Disable recommendation/extension recommendation features.
    "extensions.getAddons.showPane" = false;
    "extensions.htmlaboutaddons.recommendations.enabled" = false;
    # Disable extension recommendations based on browsing/site context.
    "browser.discovery.enabled" = false;
    # Enable fingerprinting protection.
    # Firefox fingerprinting protection limits exposed browser/device details used for tracking.
    "privacy.fingerprintingProtection" = true;
    # Enable stronger cookie/storage isolation.
    # This is generally useful and less breakage-prone than full Resist Fingerprinting.
    "privacy.partition.network_state" = true;
    # Send a Global Privacy Control signal to websites.
    "privacy.globalprivacycontrol.enabled" = true;
    # Disable geolocation prompts/API.
    # Optional: remove this if you use maps, delivery sites, weather, etc.
    "geo.enabled" = false;
    # Disable WebRTC peer connections.
    # Optional: this can break browser-based calls, video meetings, and some P2P web apps.
    "media.peerconnection.enabled" = false;
    # Do not automatically disable extensions based on install scope.
    # Note: privacy-wise, 0 is less protective than the default because sideloaded extensions may stay enabled.
    # Consider using 15 unless you specifically need externally-installed extensions.
    "extensions.autoDisableScopes" = 0;
  };

  common-extensions = [
    # To add additional extensions, find it on addons.mozilla.org, find
    # the short ID in the url (like https://addons.mozilla.org/en-US/firefox/addon/!SHORT_ID!/)
    # Then go to https://addons.mozilla.org/api/v5/addons/addon/!SHORT_ID!/ to get the guid
    (extension "ublock-origin" "uBlock0@raymondhill.net")
    (extension "bitwarden-password-manager" "{446900e4-71c2-419f-a6a7-df9c091e268b}")
  ];

  all-extensions = common-extensions ++ (builtins.attrValues (lib.mapAttrs extension extensions));
  all-prefs = common-prefs // prefs;
in {
  extraPrefs = lib.concatLines (
    lib.mapAttrsToList (
      name: value: ''lockPref(${lib.strings.toJSON name}, ${lib.strings.toJSON value});''
    )
    all-prefs
  );
  extraPolicies =
    {
      AutofillAddressEnabled = false;
      AutofillCreditCardEnabled = false;

      DisableAppUpdate = true;
      DisableFeedbackCommands = true;
      DisableFirefoxStudies = true;
      DisablePocket = true;
      DisableProfileImport = true;
      DisableTelemetry = true;
      DisplayBookmarksToolbar = "always";
      DontCheckDefaultBrowser = true;
      NoDefaultBookmarks = true;
      OverrideFirstRunPage = "";

      ExtensionSettings = builtins.listToAttrs all-extensions;

      SearchEngines = {
        PreventInstalls = true;
        Default = "ddg";
        Remove = [
          "eBay"
          "Bing"
          "Ecosia"
          "Perplexity"
        ];
        Add = [
          {
            Name = "Nix Packages";
            IconURL = "https://search.nixos.org/favicon.png";
            Alias = "@np";
            Method = "GET";
            URLTemplate = "https://search.nixos.org/packages?channel=unstable&query={searchTerms}";
          }
          {
            Name = "Nix Options";
            IconURL = "https://search.nixos.org/favicon.png";
            Alias = "@no";
            Method = "GET";
            URLTemplate = "https://search.nixos.org/options?channel=unstable&query={searchTerms}";
          }
          {
            Name = "Nix Wiki";
            IconUrl = "https://wiki.nixos.org/favicon.ico";
            Alias = "@nw";
            Method = "GET";
            URLTemplate = "https://wiki.nixos.org/w/index.php?search={searchTerms}";
          }
          {
            Name = "Noogle";
            IconURL = "https://noogle.dev/favicon.png";
            Alias = "@noo";
            Method = "GET";
            URLTemplate = "https://noogle.dev/q?term={searchTerms}";
          }
        ];
      };

      SearchSuggestEnabled = false;
    }
    // policies;
}
