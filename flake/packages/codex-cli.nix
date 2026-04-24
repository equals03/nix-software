{inputs, ...}: {
  perSystem = {
    system,
    lib,
    ...
  }: let
    codex-cli = inputs.codex-cli.packages.${system}.default or null;
  in {
    packages = lib.optionalAttrs (codex-cli != null) {
      inherit codex-cli;
    };
  };
}
