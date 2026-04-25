{lib, ...}: let
  package = {
    lib,
    fetchFromGitHub,
    rustPlatform,
  }:
    rustPlatform.buildRustPackage rec {
      pname = "lean-ctx";
      version = "3.4.1";

      src = fetchFromGitHub {
        owner = "yvgude";
        repo = "lean-ctx";
        rev = "v${version}";
        hash = "sha256-+RwUAA/hEqSlMb2CJ0bziZesBKSGaNQ1ibuKve0yM64=";
      };

      cargoHash = "sha256-uXEPQ7QuvBw3YXjGreyfVrQP2diByrW8EGtBOiy592c=";
      sourceRoot = "source/rust";

      doCheck = false;

      meta = with lib; {
        description = "Context optimizer for AI coding tools";
        homepage = "https://github.com/yvgude/lean-ctx";
        license = licenses.asl20;
        mainProgram = "lean-ctx";

        # enrol in the custom 'update-packages' script
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
