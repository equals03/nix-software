{lib, ...}: {
  perSystem = {
    self',
    pkgs,
    ...
  }: let
    packages = self'.packages or {};

    updatable = lib.filterAttrs (_: pkg: pkg.meta.update.enable or false) packages;

    mkLine = name: pkg: let
      inherit (pkg.meta) update;
      params = update.params or [];
    in {
      inherit name params;
    };

    specs = lib.mapAttrsToList mkLine updatable;

    knownNames = builtins.attrNames updatable;

    runOne = spec: ''
      echo "==> updating ${lib.escapeShellArg spec.name}"
      nix-update ${lib.escapeShellArg spec.name} \
        --flake \
        ${lib.concatStringsSep " " (map lib.escapeShellArg spec.params)}
    '';

    caseArms =
      lib.concatStringsSep "\n"
      (map
        (spec: ''
          ${lib.escapeShellArg spec.name})
            ${runOne spec}
            ;;
        '')
        specs);

    update-packages = pkgs.writeShellApplication {
      name = "update-packages";
      runtimeInputs = [pkgs.nix-update];
      text = ''
        set -euo pipefail

        usage() {
          echo "Usage:"
          echo "  update-packages            # update all enrolled packages"
          echo "  update-packages <name>     # update one package"
        }

        update_all() {
          ${
          if specs == []
          then ":"
          else lib.concatStringsSep "\n" (map runOne specs)
        }
        }

        update_one() {
          case "$1" in
            ${caseArms}
            *)
              echo "unknown package: $1" >&2
              echo "known packages: ${lib.concatStringsSep ", " knownNames}" >&2
              exit 1
              ;;
          esac
        }

        case "''${1-}" in
          ""|all)
            update_all
            ;;
          -h|--help)
            usage
            ;;
          *)
            update_one "$1"
            ;;
        esac
      '';
    };
  in {
    apps.update-packages = {
      type = "app";
      program = update-packages;
    };
  };
}
