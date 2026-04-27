{
  lib,
  flake-parts-lib,
  ...
}: let
  inherit
    (lib)
    mkOption
    types
    ;
  inherit
    (flake-parts-lib)
    mkTransposedPerSystemModule
    ;
in
  mkTransposedPerSystemModule {
    name = "ci-checks";
    option = mkOption {
      type = types.lazyAttrsOf types.package;
      default = {};
      description = ''
        Derivations to be built by within ci.
      '';
    };
    file = ./ci-checks.nix;
  }
