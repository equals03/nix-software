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

    zen-browser-unwrapped = inputs.zen-browser.packages.${system}.zen-browser-unwrapped or null;
    zen-browser = pkgs.wrapFirefox zen-browser-unwrapped (shared-browser-policies {
      inherit prefs;
    });
  in {
    packages = lib.optionalAttrs (zen-browser-unwrapped != null) {
      inherit zen-browser zen-browser-unwrapped;
    };
  };
}
