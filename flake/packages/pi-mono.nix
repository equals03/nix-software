{
  inputs,
  lib,
  ...
}: let
  version = "0.70.2";
  rev = "v${version}";
  hash = "sha256-qqmJloTp3mWuZBGgpwoyoFyXx6QD8xhJEwCZb7xFabM=";
  npmDepsHash = "sha256-ImDvTC0Nm+IGYJuqjwUUfnOtA65uJvjlpP4h2Xt/2vE=";

  package = {
    src,
    callPackage,
    ...
  }: let
    pi-mono = callPackage "${inputs.pi-mono}/coding-agent/package.nix" {
      inherit src version npmDepsHash;
    };
  in
    pi-mono;
in {
  perSystem = {
    pkgs,
    system,
    ...
  }: let
    src = pkgs.fetchFromGitHub {
      owner = "badlogic";
      repo = "pi-mono";
      inherit rev hash;
    };
    pi-mono = (pkgs.callPackage package {inherit src;}).overrideAttrs (_final: prev:
      prev
      // {
        preBuild =
          prev.preBuild
          + ''
            substituteInPlace tsconfig.base.json \
            --replace-fail  '"target": "ES2022"' \
                            '"target": "ES2024"'
          '';
      });
  in {
    packages = lib.optionalAttrs (builtins.elem system pi-mono.meta.platforms) {
      inherit pi-mono;
    };
  };
}
