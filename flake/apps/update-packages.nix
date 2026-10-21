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

    attemptCall = spec:
      "attempt ${lib.escapeShellArg spec.name} "
      + lib.concatStringsSep " " (map lib.escapeShellArg (
        ["nix-update" spec.name "--flake"] ++ spec.params
      ));

    attempts =
      if specs == []
      then ":"
      else lib.concatMapStrings (spec: "  ${attemptCall spec}\n") specs;

    caseArms = lib.concatMapStrings (spec:
      "    ${lib.escapeShellArg spec.name})\n"
      + "      ${attemptCall spec}\n"
      + "      ;;\n")
    specs;

    update-packages = pkgs.writeShellApplication {
      name = "update-packages";
      runtimeInputs = [pkgs.nix-update pkgs.gitMinimal];
      text = ''
        set -euo pipefail

        root=$(git rev-parse --show-toplevel)
        cd "$root"

        # Names whose nix-update failed. Their files are restored; earlier
        # successes in this run stay in the worktree. Exit 2 so CI can open
        # a PR for those successes and still mark the run failed.
        failures=()

        usage() {
          cat <<'EOF'
        Usage:
          update-packages            # update all enrolled packages
          update-packages <name>     # update one package

        Exits 2 when a package update fails. That package is restored.
        Earlier successes in the same run are kept.
        EOF
        }

        restore_snapshot() {
          local scratch="$1"
          local after new_untracked path
          after=$(mktemp)
          new_untracked=$(mktemp)
          git ls-files --others --exclude-standard | sort > "$after"
          comm -13 "$scratch/untracked" "$after" > "$new_untracked"
          while IFS= read -r path; do
            [ -n "$path" ] || continue
            rm -rf -- "$path"
          done < "$new_untracked"
          rm -f "$after" "$new_untracked"

          if [ -s "$scratch/wip" ]; then
            git restore --source="$(cat "$scratch/wip")" --worktree --staged .
          else
            git restore --source=HEAD --worktree --staged .
          fi
        }

        attempt() {
          local name="$1"
          shift
          local scratch wip
          scratch=$(mktemp -d)
          # Empty when the worktree matches HEAD. Does not move HEAD.
          wip=$(git -c user.email=update-packages@localhost -c user.name=update-packages stash create)
          printf '%s' "$wip" > "$scratch/wip"
          git ls-files --others --exclude-standard | sort > "$scratch/untracked"

          echo "==> updating $name"
          if "$@"; then
            rm -rf "$scratch"
            return 0
          fi

          restore_snapshot "$scratch"
          rm -rf "$scratch"
          failures+=("$name")
          echo "failed to update $name; restored its files" >&2
          echo "failed-update $name" >&2
        }

        update_all() {
          ${attempts}
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
            exit 0
            ;;
          *)
            update_one "$1"
            ;;
        esac

        if (( ''${#failures[@]} > 0 )); then
          echo "Failed updates:" >&2
          printf '  %s\n' "''${failures[@]}" >&2
          exit 2
        fi
      '';
    };
  in {
    apps.update-packages = {
      type = "app";
      program = update-packages;
    };
  };
}
