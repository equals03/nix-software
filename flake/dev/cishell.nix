{
  perSystem = {
    system,
    pkgs,
    ...
  }: let
    packages = with pkgs; [
      attic-client
      nix-fast-build
    ];
  in {
    devshells = {
      ci = let
        motd = "";
      in {
        inherit motd packages;
        name = "ci-shell";

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
        ];

        commands = [
          {
            category = "ci";
            name = "build";
            command = ''
              nix-fast-build \
                --flake ".#ci-checks.${system}" \
                --no-nom \
                --skip-cached
            '';
          }
          {
            category = "ci";
            name = "build-and-push";
            command = ''
              nix-fast-build \
                --flake ".#ci-checks.${system}" \
                --no-nom \
                --skip-cached \
                --attic-cache "default:''$ATTIC_CACHE"
            '';
          }
          {
            category = "ci";
            name = "attic-init";
            command = ''
              attic login default "''$ATTIC_ENDPOINT" "''$ATTIC_TOKEN" --set-default
              attic use "default:''$ATTIC_CACHE"
            '';
          }
        ];
      };
    };
  };
}
