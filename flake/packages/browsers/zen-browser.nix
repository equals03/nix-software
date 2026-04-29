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
    inherit (browsers) zen-browser-unwrapped;
    zen-browser = pkgs.wrapFirefox zen-browser-unwrapped (shared-browser-policies {
      inherit prefs;
    });
  in {
    packages = lib.optionalAttrs (browsers != null) {
      inherit zen-browser zen-browser-unwrapped;
    };
  };
}
