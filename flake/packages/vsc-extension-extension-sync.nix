{lib, ...}: let
  package = {
    lib,
    vscode-utils,
    vscode,
  }:
    vscode-utils.buildVscodeMarketplaceExtension {
      mktplcRef = {
        name = "extension-sync";
        publisher = "e4mi";
        version = "0.1.1";
        hash = "sha256-bGtQS+Wr+7op1mRdlNvHJAPV1T/5YskQf1hQIkFktTg=";
      };

      meta = {
        description = "Save installed extensions in your User Settings JSON file.";
        downloadPage = "https://marketplace.visualstudio.com/items?itemName=e4mi.extension-sync";
        homepage = "https://codeberg.org/e4mi/extension-sync";
        license = lib.licenses.mit;
        maintainers = [lib.maintainers.e4mi];
        inherit (vscode.meta) platforms;
      };
    };
in {
  perSystem = {
    pkgs,
    system,
    ...
  }: let
    vsc-extension-extension-sync = pkgs.callPackage package {};
  in {
    packages = lib.optionalAttrs (builtins.elem system vsc-extension-extension-sync.meta.platforms) {
      inherit vsc-extension-extension-sync;
    };
  };
}
