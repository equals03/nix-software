{lib, ...}: let
  package = {
    lib,
    buildGoModule,
    fetchFromGitHub,
    versionCheckHook,
  }:
    buildGoModule (finalAttrs: {
      pname = "ttt";
      version = "1.9.0";

      src = fetchFromGitHub {
        owner = "eugenioenko";
        repo = "ttt";
        tag = "v${finalAttrs.version}";
        hash = "sha256-aksoLKP/ShUS22Q/BaesK26LBuJfxbyd2esLkamhmMs=";
      };

      vendorHash = "sha256-Rlv/akRDQwbbpGblCaVoWRPQnspg0Ijt7bpm3jYmDeE=";

      ldflags = [
        "-s"
        "-w"
        "-X main.version=${finalAttrs.version}"
      ];

      subPackages = ["cmd/ttt"];

      # TUI tests need a terminal. The release already ran them.
      doCheck = false;
      doInstallCheck = true;
      nativeInstallCheckInputs = [versionCheckHook];

      meta = {
        description = "Terminal Text Tool, an IDE that lives in your terminal";
        homepage = "https://github.com/eugenioenko/ttt";
        changelog = "https://github.com/eugenioenko/ttt/releases/tag/v${finalAttrs.version}";
        license = lib.licenses.mit;
        mainProgram = "ttt";
        platforms = lib.platforms.unix;
        maintainers = [];

        # enroll in the custom 'update-packages' script
        update.enable = true;
      };
    });
in {
  perSystem = {
    pkgs,
    system,
    ...
  }: let
    ttt = pkgs.callPackage package {};
  in {
    packages = lib.optionalAttrs (builtins.elem system ttt.meta.platforms) {
      inherit ttt;
    };
  };
}
