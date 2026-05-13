{lib, ...}: let
  package = {
    lib,
    fetchFromGitHub,
    rustPlatform,
  }:
    rustPlatform.buildRustPackage rec {
      pname = "lean-ctx";
      version = "3.5.22";

      src = fetchFromGitHub {
        owner = "yvgude";
        repo = "lean-ctx";
        rev = "v${version}";
        hash = "sha256-dw8ZTxSK5dCOdCJgJqjG2b1KsRk7924Z+uXDvwCQNRU=";
      };

      cargoHash = "sha256-ZQNxcka3rVci1dl8uKOGqrhC+49jEHBtCryW4smSeOY=";
      sourceRoot = "source/rust";

      # tests fail within the nix sandbox due to mutations
      # TODO: selectively exclude failing tests
      doCheck = false;

      meta = with lib; {
        description = "Context optimizer for AI coding tools";
        homepage = "https://github.com/yvgude/lean-ctx";
        license = licenses.asl20;
        mainProgram = "lean-ctx";
        maintainers = [];

        # enroll in the custom 'update-packages' script
        update.enable = true;
      };
    };
in {
  perSystem = {
    pkgs,
    system,
    ...
  }: let
    lean-ctx = pkgs.callPackage package {};
  in {
    packages = lib.optionalAttrs (builtins.elem system lean-ctx.meta.platforms) {
      inherit lean-ctx;
    };
  };
}
