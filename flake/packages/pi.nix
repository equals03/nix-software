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
    fetchFromGitHub,
    rsync,
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

      npmPruneFlags = ["--omit=dev"];

      nativeBuildInputs = [
        makeWrapper
        pkg-config
        typescript
        typescript-go
        rsync
      ];

      buildInputs = [
        pixman
        cairo
        pango
        libpng
        libjpeg
        giflib
        librsvg
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

        # Remove dev dependencies before copying runtime dependencies.
        npm prune --omit=dev

        mkdir -p $out/bin $out/lib/node_modules/@mariozechner

        # install workspace packages using their real package.json "name",
        # rather than guessing @mariozechner/pi-$pkg.
        for pkg in tui ai agent coding-agent mom pods; do
          [ -d "packages/$pkg/dist" ] || continue

          packageName="$(node -p "require('./packages/$pkg/package.json').name")"
          packageOut="$out/lib/node_modules/$packageName"

          mkdir -p "$packageOut"

          # Preserve dist/ so paths like dist/cli.js still exist.
          cp -r "packages/$pkg/dist" "$packageOut/dist"

          cp "packages/$pkg/package.json" "$packageOut/"
        done

        # Copy third-party node_modules, excluding local workspace packages that were
        # installed manually above.
        rsync -a \
          --exclude='/@mariozechner/pi-tui' \
          --exclude='/@mariozechner/pi-ai' \
          --exclude='/@mariozechner/pi-agent-core' \
          --exclude='/@mariozechner/pi-coding-agent' \
          --exclude='/@mariozechner/pi-mom' \
          --exclude='/@mariozechner/pi-pods' \
          node_modules/ "$out/lib/node_modules/"

        # Remove dangling symlinks left by pruned/excluded workspace deps.
        find -L "$out/lib/node_modules" -type l -delete

        # Remove non-runtime Python helper/source scripts whose patched shebangs pull
        # Python into the runtime closure.
        rm -f \
          "$out/lib/node_modules/katex/src/fonts/generate_fonts.py" \
          "$out/lib/node_modules/katex/src/metrics/extract_tfms.py" \
          "$out/lib/node_modules/katex/src/metrics/extract_ttfs.py" \
          "$out/lib/node_modules/katex/src/metrics/format_json.py" \
          "$out/lib/node_modules/koffi/lib/native/base/crc_gen.py" \
          "$out/lib/node_modules/koffi/lib/native/base/mimetypes_gen.py" \
          "$out/lib/node_modules/koffi/lib/native/base/unicode_gen.py" \
          "$out/lib/node_modules/shell-quote/print.py"


        makeWrapper ${nodejs}/bin/node $out/bin/pi \
          --add-flags "$out/lib/node_modules/@mariozechner/pi-coding-agent/dist/cli.js" \
          --set PI_PACKAGE_DIR "$out/lib/node_modules/@mariozechner/pi-coding-agent" \
          --prefix NODE_PATH : "$out/lib/node_modules"

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
