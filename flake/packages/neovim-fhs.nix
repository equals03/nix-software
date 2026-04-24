{lib, ...}: let
  package = {
    buildFHSEnv,
    writeShellScript,
    neovim,
  }: let
    fhs = {additionalPkgs ? (_: []), ...}:
      buildFHSEnv {
        inherit (neovim) version;
        meta = {
          inherit (neovim.meta) license platforms;
        };

        name = "nvim-fhs";
        targetPkgs = pkgs:
          [neovim]
          ++ (with pkgs; [
            glibc
            curl
            wl-clipboard
          ])
          ++ (additionalPkgs pkgs);

        runScript = writeShellScript "nvim-fhs.sh" ''
          exec ${neovim}/bin/nvim "$@"
        '';
      };
  in
    fhs {} // {withPackages = additionalPkgs: fhs {inherit additionalPkgs;};};
in {
  perSystem = {
    pkgs,
    system,
    ...
  }: let
    neovim-fhs = pkgs.callPackage package {};
  in {
    packages = lib.optionalAttrs (builtins.elem system neovim-fhs.meta.platforms) {
      inherit neovim-fhs;
    };
  };
}
