{lib, ...}: let
  package = {
    buildFHSEnv,
    #writeShellScript,
    neovim,
    # Customize FHS environment
    # Function that takes default buildFHSEnv arguments and returns modified arguments
    customizeFHSEnv ? args: args,
  }: let
    fhs = {additionalPkgs ? _pkgs: []}: let
      inherit (neovim) pname version;
      inherit (neovim.meta) mainProgram;

      defaultArgs = {
        inherit pname version;
        executableName = mainProgram;

        # additional libraries which are commonly needed for extensions
        targetPkgs = pkgs:
          (with pkgs; [
            glibc
            curl
            wl-clipboard

            # dotnet
            curl
            icu
            libunwind
            libuuid
            lttng-ust
            openssl
            zlib
          ])
          ++ additionalPkgs pkgs;

        extraBwrapArgs = [
          "--bind-try /etc/nixos/ /etc/nixos/"
          "--ro-bind-try /etc/xdg/ /etc/xdg/"
        ];

        # symlink shared assets, including icons and desktop entries
        extraInstallCommands = ''
          ln -s "${neovim}/share" "$out/"
        '';

        runScript = "${neovim}/bin/${mainProgram}";

        passthru = {
          inherit pname version;
        };

        meta =
          neovim.meta
          // {
            description = "Wrapped variant of ${pname} which launches in a FHS compatible environment, should allow for easy usage of extensions without nix-specific modifications";
          };
      };
      customizedArgs = customizeFHSEnv defaultArgs;
    in
      buildFHSEnv customizedArgs;

    withPackages = additionalPkgs: fhs {inherit additionalPkgs;};
  in
    neovim
    // {
      fhs = fhs {} // {inherit withPackages;};
      fhsWithPackages = withPackages;
    };
in {
  perSystem = {
    pkgs,
    system,
    ...
  }: let
    neovim = pkgs.callPackage package {};
    neovim-fhs = neovim.fhs;
  in {
    packages = lib.optionalAttrs (builtins.elem system neovim-fhs.meta.platforms) {
      inherit neovim neovim-fhs;
    };
  };
}
