{
  inputs,
  lib,
  ...
}: let
  package = {
    pkgs,
    callPackage,
    jq,
    moreutils,
    stdenv,
    ...
  }: let
    buildVscode = callPackage "${pkgs.path}/pkgs/applications/editors/vscode/generic.nix" {};
    code-cursor = callPackage "${inputs.cursor}/cursor.nix" {
      inherit buildVscode;
    };

    ripgrepSystem =
      {
        x86_64-darwin = "darwin-x64";
        aarch64-darwin = "darwin-arm64";
        armv7l-linux = "linux-arm";
        aarch64-linux = "linux-arm64";
        i686-linux = "linux-ia32";
        powerpc64-linux = "linux-ppc64";
        riscv64-linux = "linux-riscv64";
        s390x-linux = "linux-s390x";
        x86_64-linux = "linux-x64";
      }.${
        stdenv.hostPlatform.system
      } or (throw "Unknown system for ripgrep-universal: ${stdenv.hostPlatform.system}");
  in
    code-cursor.overrideAttrs (orig: let
      dest = "lib/cursor/resources/app";
      gallery = builtins.toJSON {
        serviceUrl = "https://marketplace.visualstudio.com/_apis/public/gallery";
        itemUrl = "https://marketplace.visualstudio.com/items";
        cacheUrl = "https://vscode.blob.core.windows.net/gallery/index";
        controlUrl = "";
      };
    in {
      nativeBuildInputs = orig.nativeBuildInputs ++ [jq moreutils];

      autoPatchelfIgnoreMissingDeps =
        (orig.autoPatchelfIgnoreMissingDeps or [])
        ++ [
          "libc.musl-x86_64.so.1"
        ];

      # hack: seems like cursor is using ripgrep in another location?
      postPatch =
        lib.replaceStrings
        ["@vscode/ripgrep-universal/bin/${ripgrepSystem}"]
        ["@vscode/ripgrep/bin"]
        (orig.postPatch or "");

      postInstall =
        (orig.postInstall or "")
        + ''
          PRODUCT_JSON=$out/${dest}/product.json
          jq --argjson gallery '${gallery}' \
              '.extensionsGallery = $gallery' \
              "$PRODUCT_JSON" | sponge "$PRODUCT_JSON"
        '';
    });
in {
  perSystem = {
    pkgs,
    system,
    ...
  }: let
    code-cursor = pkgs.callPackage package {};
    code-cursor-fhs = code-cursor.fhs;
  in {
    packages = lib.optionalAttrs (builtins.elem system code-cursor.meta.platforms) {
      inherit code-cursor code-cursor-fhs;
    };
  };
}
