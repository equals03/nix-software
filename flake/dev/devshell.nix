{
  perSystem = {pkgs, ...}: let
    essential = with pkgs; [
      curl
      git
      openssh
      attic-client
    ];
  in {
    devshells = {
      default = let
        programs =
          map (package: {
            inherit package;
            category = "-- programs";
          }) [
            "nix-output-monitor"
          ];

        motd = ''
          $(${pkgs.neo-cowsay}/bin/cowsay -f small --aurora "🔨 Welcome to devshell")

          $(type -p menu &>/dev/null && menu)
        '';
      in {
        inherit motd;
        name = "nix flake shell";

        packages = with pkgs;
          essential
          ++ [
            ripgrep
          ];

        env = [
          {
            name = "NIX_CONFIG";
            value = ''
              extra-experimental-features = nix-command flakes
            '';
          }
          {
            name = "FLAKE";
            eval = "$PRJ_ROOT";
          }
          {
            name = "NH_FLAKE";
            eval = "$PRJ_ROOT";
          }
        ];

        commands =
          [
            {
              category = "nix flake";
              name = "flake";
              help = "nix flake";
              command = "nix flake $@";
            }
            {
              category = "nix flake";
              name = "check";
              help = "nix flake check --log-format internal-json |& nom --json";
              command = "nix flake check --log-format internal-json $@ |& nom --json";
            }

            {
              category = "nix";
              name = "fmt";
              help = "nix fmt";
              command = "nix fmt $@";
            }

            {
              category = "build";
              name = "build";
              help = "nom build .#";
              command = "nom build .#$@";
            }
            {
              category = "build";
              name = "build-all";
              help = "nix run .#build-all-packages";
              command = "nix run .#build-all-packages $@";
            }

            {
              category = "update";
              name = "update";
              help = "nix run .#update-packages";
              command = "nix run .#update-packages $@";
            }

            {
              category = "cache";
              name = "push";
              help = "attic push software";
              command = "attic push software $@";
            }
          ]
          ++ programs;
      };
    };
  };
}
