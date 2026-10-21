{inputs, ...}: {
  perSystem = {
    system,
    pkgs,
    lib,
    ...
  }: let
    shared-browser-policies = import ./_shared/shared-browser-policies.nix {inherit lib;};

    prefs = {
      "zen.tabs.vertical.right-side" = true;
      "zen.view.use-single-toolbar" = false;
      "zen.welcome-screen.seen" = true; # OOBE
    };

    browsers = inputs.zen-browser.packages.${system} or null;
    #inherit (browsers) zen-browser-unwrapped;
    zen-browser-unwrapped =
      if browsers.zen-browser-unwrapped.version == "1.23.3b"
      then
        browsers.zen-browser-unwrapped.override {
          hash = "sha256-uyBF0+IWVNQP6EElAJLurf0sH8gx7vtQkiJ3PIvcoUk=";
        }
      else browsers.zen-browser-unwrapped;

    zen-browser = pkgs.wrapFirefox zen-browser-unwrapped (shared-browser-policies {
      inherit prefs;
    });
  in {
    packages = lib.optionalAttrs (browsers != null) {
      inherit zen-browser zen-browser-unwrapped;
    };
  };
}
