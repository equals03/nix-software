{lib, ...}: let
  package = {
    lib,
    fetchFromGitHub,
    rustPlatform,
  }:
    rustPlatform.buildRustPackage rec {
      pname = "lean-ctx";
      version = "3.6.6";

      src = fetchFromGitHub {
        owner = "yvgude";
        repo = "lean-ctx";
        rev = "v${version}";
        hash = "sha256-1EtJ+GCC05bVez79xhk52/Jc9ImnmtJN6DDfKVU2ApE=";
      };

      cargoHash = "sha256-9k8V29weVH88CLEtLKq5HK1OiAUmsCVTyp8yJU4bMLM=";
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
