{lib, ...}: let
  package = {
    lib,
    stdenv,
    fetchurl,
    autoPatchelfHook,
    versionCheckHook,
  }:
    stdenv.mkDerivation (finalAttrs: {
      pname = "noodle";
      version = "0.10.2";

      src = fetchurl {
        url = "https://github.com/wilfredinni/noodle/releases/download/v${finalAttrs.version}/noodle-linux-x86_64";
        hash = "sha256-X9suVTAWJTVYhAKl/QrG068AstWvldkm0zA9DhyE+y4=";
      };

      dontUnpack = true;

      # Bun's standalone executable stores its payload after the ELF image.
      dontStrip = true;

      nativeBuildInputs = [
        autoPatchelfHook
      ];

      installPhase = ''
        runHook preInstall

        install -Dm755 "$src" "$out/bin/noodle"

        runHook postInstall
      '';

      doInstallCheck = true;
      nativeInstallCheckInputs = [versionCheckHook];

      meta = {
        description = "Terminal REST client that keeps collections as versioned files";
        longDescription = ''
          Noodle is a terminal REST client. Requests live in YAML beside the
          code they exercise, and the same files drive the TUI, the CLI, and
          scripts.
        '';
        homepage = "https://noodlerest.dev/";
        changelog = "https://github.com/wilfredinni/noodle/releases/tag/v${finalAttrs.version}";
        license = lib.licenses.asl20;
        sourceProvenance = with lib.sourceTypes; [
          binaryNativeCode
        ];
        platforms = ["x86_64-linux"];
        mainProgram = "noodle";
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
    noodle = pkgs.callPackage package {};
  in {
    packages = lib.optionalAttrs (builtins.elem system noodle.meta.platforms) {
      inherit noodle;
    };
  };
}
