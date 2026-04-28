{lib, ...}: let
  package = {
    lib,
    buildNpmPackage,
    makeWrapper,
    nodejs,
    typescript,
    typescript-go,
    pkg-config,
    pixman,
    cairo,
    pango,
    libpng,
    libjpeg,
    giflib,
    librsvg,
    fd,
    fetchFromGitHub,
  }:
    buildNpmPackage (finalAttrs: {
      pname = "pi-coding-agent";
      version = "0.70.5";

      src = fetchFromGitHub {
        owner = "badlogic";
        repo = "pi-mono";
        tag = "v${finalAttrs.version}";
        hash = "sha256-Jn+hvS/DIwbwAff+UovdIVnmrb4o8gsC4IR24MnwF1I=";
      };

      npmDepsHash = "sha256-MZgcHJdGFGSNgQ26/24iA12FdmO7S5vWv4crSNFhHi0=";

      nativeBuildInputs = [
        makeWrapper
        pkg-config
        typescript
        typescript-go
      ];

      buildInputs = [
        pixman
        cairo
        pango
        libpng
        libjpeg
        giflib
        librsvg
        fd
      ];

      preBuild = ''
        find packages -name "package.json" -exec sed -i \
          -e 's/--watch --preserveWatchOutput//g' \
          {} \;

        for f in packages/ai/src/models.ts packages/agent/src/agent.ts; do
          [ -f "$f" ] && echo '// @ts-nocheck' | cat - "$f" > tmp && mv tmp "$f"
        done

        substituteInPlace packages/coding-agent/src/modes/interactive/interactive-mode.ts \
          --replace-fail  '"https://github.com/badlogic/pi-mono/blob/main/packages/coding-agent/CHANGELOG.md"' \
                          '`https://github.com/badlogic/pi-mono/blob/v''${newVersion}/packages/coding-agent/CHANGELOG.md`'

        substituteInPlace tsconfig.base.json \
          --replace-fail  '"target": "ES2022"' \
                          '"target": "ES2024"'
      '';

      buildPhase = ''
        runHook preBuild
        npm run build --workspace=packages/tui --workspace=packages/ai --workspace=packages/agent --workspace=packages/coding-agent
        runHook postBuild
      '';

      installPhase = ''
        runHook preInstall
        mkdir -p $out/bin $out/lib/node_modules/@mariozechner

        for pkg in tui ai agent coding-agent mom pods; do
          [ -d "packages/$pkg/dist" ] || continue
          mkdir -p "$out/lib/node_modules/@mariozechner/pi-$pkg"
          cp -r packages/$pkg/dist/* "$out/lib/node_modules/@mariozechner/pi-$pkg/"
          cp packages/$pkg/package.json "$out/lib/node_modules/@mariozechner/pi-$pkg/"
        done

        cp -rL node_modules/. "$out/lib/node_modules/"

        makeWrapper ${nodejs}/bin/node $out/bin/pi \
          --add-flags "$out/lib/node_modules/@mariozechner/pi-coding-agent/dist/cli.js" \
          --set PI_PACKAGE_DIR "$out/lib/node_modules/@mariozechner/pi-coding-agent" \
          --prefix NODE_PATH : "$out/lib/node_modules" \
          --prefix PATH : "${fd}/bin"
        runHook postInstall
      '';

      meta = {
        description = "Pi - a minimal terminal coding harness";
        homepage = "https://github.com/badlogic/pi-mono";
        license = lib.licenses.mit;
        platforms = lib.platforms.unix;
        mainProgram = "pi";
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
    pi = pkgs.callPackage package {};
  in {
    packages = lib.optionalAttrs (builtins.elem system pi.meta.platforms) {
      inherit pi;
    };
  };
}
