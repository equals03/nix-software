{lib, ...}: let
  package = {
    lib,
    buildGoModule,
    fetchFromGitHub,
    installShellFiles,
    versionCheckHook,
  }:
    buildGoModule (finalAttrs: {
      pname = "tidemail";
      version = "1.10.2";

      src = fetchFromGitHub {
        owner = "allisonhere";
        repo = "tidemail";
        tag = "v${finalAttrs.version}";
        hash = "sha256-NCSsMb17kB2YYyiuSvi7UMh8l6tAyMvZu9RCGEydats=";
      };

      vendorHash = "sha256-Ku3EWZ70b950XbJuDTvOOXF32Upk0CkbmiezXWuipoU=";

      # Upstream release builds also link in a Google OAuth client. This
      # package does not. Set TIDEMAIL_GOOGLE_CLIENT_ID and
      # TIDEMAIL_GOOGLE_CLIENT_SECRET at runtime, or use an app password.
      ldflags = [
        "-s"
        "-w"
        "-X main.version=v${finalAttrs.version}"
      ];

      env.CGO_ENABLED = "0";

      # cmd/ and examples/ are previews and sample plugins, not the client.
      subPackages = ["."];

      nativeBuildInputs = [
        installShellFiles
      ];

      postInstall = ''
        installManPage man/tidemail.1
      '';

      # TUI tests need a terminal. The release already ran them.
      doCheck = false;
      doInstallCheck = true;
      nativeInstallCheckInputs = [versionCheckHook];

      meta = {
        description = "Keyboard-first terminal email client";
        longDescription = ''
          TideMail is a terminal email client with multiple accounts, a unified
          inbox, drafts, contacts, search, and optional AI tools.
        '';
        homepage = "https://github.com/allisonhere/tidemail";
        changelog = "https://github.com/allisonhere/tidemail/releases/tag/v${finalAttrs.version}";
        license = lib.licenses.mit;
        mainProgram = "tidemail";
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
    tidemail = pkgs.callPackage package {};
  in {
    packages = lib.optionalAttrs (builtins.elem system tidemail.meta.platforms) {
      inherit tidemail;
    };
  };
}
