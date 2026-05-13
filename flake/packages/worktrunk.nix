{lib, ...}: let
  package = {
    lib,
    stdenv,
    fetchFromGitHub,
    rustPlatform,
    installShellFiles,
    versionCheckHook,
  }:
    rustPlatform.buildRustPackage (finalAttrs: {
      pname = "worktrunk";
      version = "0.50.0";

      src = fetchFromGitHub {
        owner = "max-sixty";
        repo = "worktrunk";
        tag = "v${finalAttrs.version}";
        hash = "sha256-ZCcrTXVVbB61r2tMTFwN3x5+C1i6T/wn28dviGr5rtM=";
      };

      cargoHash = "sha256-GTWoOaDjXS1Lu2JuWw1A/RYbPreivLYuhHhoWj4bFHM=";

      cargoBuildFlags = ["--package=worktrunk"];

      # vergen-gitcl calls `git describe` at build time; VERGEN_IDEMPOTENT makes it
      # fall back gracefully when no git history is available (Nix sandbox).
      env.VERGEN_IDEMPOTENT = "1";

      nativeBuildInputs = [
        installShellFiles
      ];

      postInstall = lib.optionalString (stdenv.buildPlatform.canExecute stdenv.hostPlatform) ''
        # wt reads config from $HOME; provide a throwaway dir so it doesn't fail.
        export HOME="$(mktemp -d)"

        installShellCompletion --cmd wt \
          --bash <($out/bin/wt config shell completions bash) \
          --fish <($out/bin/wt config shell completions fish) \
          --zsh  <($out/bin/wt config shell completions zsh)
      '';

      # its a release - im happy to assume the checks were already done
      doCheck = false;
      doInstallCheck = true;
      nativeInstallCheckInputs = [versionCheckHook];

      meta = {
        description = "Git worktree manager for parallel AI agent workflows";
        longDescription = ''
          worktrunk wraps git worktree with a simpler interface and integrates with
          AI coding tools like Claude Code, Cursor, and Aider.
        '';
        homepage = "https://worktrunk.dev/";
        changelog = "https://github.com/max-sixty/worktrunk/blob/v${finalAttrs.version}/CHANGELOG.md";
        license = with lib.licenses; [
          mit
          asl20
        ];
        platforms = lib.platforms.unix;
        mainProgram = "wt";
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
    worktrunk = pkgs.callPackage package {};
  in {
    packages = lib.optionalAttrs (builtins.elem system worktrunk.meta.platforms) {
      inherit worktrunk;
    };
  };
}
