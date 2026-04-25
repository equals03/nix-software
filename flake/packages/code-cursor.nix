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
    ...
  }: let
    code-cursor = callPackage "${inputs.cursor}/cursor.nix" {
      buildVscode = callPackage "${pkgs.path}/pkgs/applications/editors/vscode/generic.nix" {};
    };
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
    code-cursor-fhs = code-cursor.fhsWithPackages (ps: [ps.nixd ps.alejandra]);
  in {
    packages = lib.optionalAttrs (builtins.elem system code-cursor.meta.platforms) {
      inherit code-cursor code-cursor-fhs;
    };
  };
}
