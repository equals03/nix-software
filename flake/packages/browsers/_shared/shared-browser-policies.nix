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
    "extensions.autoDisableScopes" = 0;
    "extensions.pocket.enabled" = false;
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
        Default = "DuckDuckGo";
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
    }
    // policies;
}
