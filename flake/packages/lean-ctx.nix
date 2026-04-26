{lib, ...}: let
  package = {
    lib,
    fetchFromGitHub,
    rustPlatform,
  }:
    rustPlatform.buildRustPackage rec {
      pname = "lean-ctx";
      version = "3.4.2";

      src = fetchFromGitHub {
        owner = "yvgude";
        repo = "lean-ctx";
        rev = "v${version}";
        hash = "sha256-RLj97u0vh6mz+vAr75aznFljVmgCpR7XQ7lj9iwNm6E=";
      };

      cargoHash = "sha256-xP8EwIS6ZGeSi6sLGCggNw0OSjkYGTF0N80+dCIMwz8=";
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
