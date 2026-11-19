{lib, ...}: let
  package = {
    lib,
    buildGoModule,
    fetchFromGitHub,
    versionCheckHook,
  }:
    buildGoModule (finalAttrs: {
      pname = "ttt";
      version = "1.12.1";

      src = fetchFromGitHub {
        owner = "eugenioenko";
        repo = "ttt";
        tag = "v${finalAttrs.version}";
        hash = "sha256-pakREZDSlQjh4W4d83liuwy6M4B8xaZi5YWdBiwm7CY=";
      };

      vendorHash = "sha256-Snis8gmPqxuuO9+RJxEasHlUg5GVdV6GgNH4UTkCBvs=";

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
