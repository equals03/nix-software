{lib, ...}: {
  perSystem = {
    self',
    pkgs,
    ...
  }: let
    packages = self'.packages or {};

    packageList =
      lib.mapAttrsToList
      (name: pkg: {
        inherit name pkg;
        displayName =
          if pkg ? version
          then "${name} (${pkg.version})"
          else name;
      })
      packages;

    build-all-packages = pkgs.writeShellApplication {
      name = "build-all-packages";
      runtimeInputs = with pkgs; [nix nix-output-monitor];

      text = ''
        set -euo pipefail

        ${
          if packageList == []
          then ''
            echo "No packages to build."
          ''
          else
            lib.concatStringsSep "\n" (map (spec: ''
                echo "==> building ${lib.escapeShellArg spec.displayName}"
                nom build ".#${lib.escapeShellArg spec.name}" --no-link
              '')
              packageList)
        }
      '';
    };
  in {
    apps.build-all-packages = {
      type = "app";
      program = "${build-all-packages}/bin/build-all-packages";
    };
  };
}
