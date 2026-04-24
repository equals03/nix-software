{lib, ...}: let
  package = {
    lib,
    fetchFromGitHub,
    rustPlatform,
  }:
    rustPlatform.buildRustPackage rec {
      pname = "lean-ctx";
      version = "3.3.9";

      src = fetchFromGitHub {
        owner = "yvgude";
        repo = "lean-ctx";
        rev = "v${version}";
        hash = "sha256-QOi8GEBo8TAQQDvvvlXp27vJF16NtSmhkDeIg0oASmU=";
      };

      cargoHash = "sha256-KUCHld302ChZXU8szKLLHMWmmec28Frgf7UHQBCgH+s=";
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
