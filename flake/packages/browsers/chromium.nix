{lib, ...}: {
  perSystem = {
    pkgs,
    system,
    ...
  }: let
    package = pkgs.chromium;
  in {
    pax.packages = lib.optionalAttrs (builtins.elem system package.meta.platforms) {
      chromium = {
        inherit package;
        env = {
          GOOGLE_DEFAULT_CLIENT_ID = "77185425430.apps.googleusercontent.com";
          GOOGLE_DEFAULT_CLIENT_SECRET = "OTJgUOQcT7lO7GsGZq2G4IlT";
        };
        binaries = let
          args = ["--disable-default-browser-promo"];
        in {
          chromium = {
            inherit args;
          };
          chromium-browser = {
            inherit args;
          };
        };
      };
    };
  };
}
