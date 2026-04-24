{
  perSystem = {
    pkgs,
    lib,
    ...
  }: let
    shared-browser-policies = import ./_shared/shared-browser-policies.nix {inherit lib;};

    inherit (pkgs) firefox-unwrapped;
    firefox = pkgs.wrapFirefox firefox-unwrapped (shared-browser-policies {});
  in {
    packages = {
      inherit firefox;
    };
  };
}
