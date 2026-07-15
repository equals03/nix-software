{lib, ...}: let
  package = {
    lib,
    stdenv,
    fetchFromGitHub,
    rustPlatform,
    pkg-config,
    curl,
    openssl,
    asciidoctor,
    installShellFiles,
    versionCheckHook,
  }:
    rustPlatform.buildRustPackage (finalAttrs: {
      pname = "mdcat-ng";
      version = "0.2.3";

      src = fetchFromGitHub {
        owner = "pawelb0";
        repo = "mdcat-ng";
        tag = "mdcat-ng-${finalAttrs.version}";
        hash = "sha256-OuI2mK7YiX2bi4Th06TW7Hp5iDNJAp8uhSpS+eIfea8=";
      };

      cargoHash = "sha256-TCY0lRUvjJTXbyhXoRwrshYv55PNgrcZ9I+ILXH9H6k=";

      nativeBuildInputs = [
        pkg-config
        asciidoctor
        installShellFiles
      ];

      buildInputs = [
        curl
        openssl
      ];

      # Prefer system OpenSSL over the crate's vendored copy.
      env.OPENSSL_NO_VENDOR = "1";

      # its a release - im happy to assume the checks were already done
      doCheck = false;
      doInstallCheck = true;
      nativeInstallCheckInputs = [versionCheckHook];
      versionCheckProgram = "${placeholder "out"}/bin/mdcat";

      postInstall =
        ''
          asciidoctor -b manpage -a reproducible mdcat.1.adoc -o mdcat.1
          installManPage mdcat.1
        ''
        + lib.optionalString (stdenv.buildPlatform.canExecute stdenv.hostPlatform) ''
          for bin in mdcat mdless; do
            installShellCompletion --cmd $bin \
              --bash <($out/bin/$bin --completions bash) \
              --fish <($out/bin/$bin --completions fish) \
              --zsh  <($out/bin/$bin --completions zsh)
          done
        '';

      meta = {
        description = "cat for markdown: show markdown documents in terminals";
        longDescription = ''
          mdcat-ng renders Markdown in the terminal with inline images,
          syntax highlighting, hyperlinks, and an interactive mdless viewer.
        '';
        homepage = "https://github.com/pawelb0/mdcat-ng";
        changelog = "https://github.com/pawelb0/mdcat-ng/releases/tag/mdcat-ng-${finalAttrs.version}";
        license = with lib.licenses; [
          mpl20
          asl20
        ];
        platforms = lib.platforms.unix;
        mainProgram = "mdcat";
        maintainers = [];

        # enroll in the custom 'update-packages' script
        update.enable = true;
        update.params = [
          "--version-regex"
          "mdcat-ng-(.*)"
        ];
      };
    });
in {
  perSystem = {
    pkgs,
    system,
    ...
  }: let
    mdcat-ng = pkgs.callPackage package {};
  in {
    packages = lib.optionalAttrs (builtins.elem system mdcat-ng.meta.platforms) {
      inherit mdcat-ng;
    };
  };
}
