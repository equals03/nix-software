{
  perSystem = {pkgs, ...}: let
    update-inputs-resilient = pkgs.writeShellApplication {
      name = "update-inputs-resilient";

      runtimeInputs = with pkgs; [
        coreutils
        git
        gnugrep
        jq
        nix
      ];

      text = ''
        set -euo pipefail

        # Set UPDATE_NIXPKGS=1 if you want nixpkgs included.
        include_nixpkgs="''${UPDATE_NIXPKGS:-0}"

        mapfile -t inputs < <(
          nix flake metadata --json \
            | jq -r '.locks.nodes.root.inputs[]' \
            | sort -u \
            | if [ "$include_nixpkgs" = "1" ]; then
                cat
              else
                grep -v '^nixpkgs$'
              fi
        )

        passed=()
        failed=()
        skipped=()

        git diff --quiet || {
          echo "Working tree must be clean before running updater." >&2
          exit 1
        }

        if [ "''${#inputs[@]}" -eq 0 ]; then
          echo "No flake inputs found to update."
          exit 0
        fi

        check_update() {
          echo "==> Running validation"
          nix flake check
        }

        print_list() {
          local title="$1"
          shift

          echo "$title"

          if [ "$#" -eq 0 ]; then
            echo "  none"
          else
            printf '  %s\n' "$@"
          fi
        }

        for input in "''${inputs[@]}"; do
          echo
          echo "========================================"
          echo "==> Trying update: $input"
          echo "========================================"

          before="$(mktemp)"
          cp flake.lock "$before"

          if nix flake update "$input"; then
            if cmp -s "$before" flake.lock; then
              echo "==> SKIP: $input produced no lockfile change"
              skipped+=("$input")
              rm -f "$before"
              continue
            fi

            if check_update; then
              echo "==> PASS: $input"
              passed+=("$input")
            else
              echo "==> FAIL validation: $input"
              cp "$before" flake.lock
              failed+=("$input")
            fi
          else
            echo "==> FAIL update: $input"
            cp "$before" flake.lock
            failed+=("$input")
          fi

          rm -f "$before"
        done

        echo
        echo "========================================"
        echo "Update summary"
        echo "========================================"

        print_list "Passed:" "''${passed[@]}"
        echo
        print_list "Skipped:" "''${skipped[@]}"
        echo
        print_list "Failed:" "''${failed[@]}"

        echo
        echo "Final changed files:"
        git status --short

        echo
        echo "Markdown summary:"
        echo
        echo "## Successful updates"
        echo
        if [ "''${#passed[@]}" -eq 0 ]; then
          echo "- none"
        else
          printf -- "- %s\n" "''${passed[@]}"
        fi

        echo
        echo "## Skipped updates"
        echo
        if [ "''${#skipped[@]}" -eq 0 ]; then
          echo "- none"
        else
          printf -- "- %s\n" "''${skipped[@]}"
        fi

        echo
        echo "## Failed updates"
        echo
        if [ "''${#failed[@]}" -eq 0 ]; then
          echo "- none"
        else
          printf -- "- %s\n" "''${failed[@]}"
        fi
      '';
    };
  in {
    apps.update-inputs-resilient = {
      type = "app";
      program = "${update-inputs-resilient}/bin/update-inputs-resilient";
    };
  };
}
