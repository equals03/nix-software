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
          {
            name = "ATTIC_SERVER_NAME";
            eval = ''''${ATTIC_SERVER_NAME:-equals03}'';
          }
          {
            name = "ATTIC_CACHE";
            eval = ''''${ATTIC_CACHE:-software}'';
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
                --attic-cache "''$ATTIC_CACHE"
            '';
          }
          {
            category = "ci";
            name = "attic-init";
            command = ''
              attic login "''$ATTIC_SERVER_NAME" "''$ATTIC_ENDPOINT" "''$ATTIC_TOKEN" --set-default
              attic use "''${ATTIC_SERVER_NAME}:''${ATTIC_CACHE}"
            '';
          }
        ];
      };
    };
  };
}
