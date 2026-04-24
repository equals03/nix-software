{inputs, ...}: {
  perSystem = {
    system,
    lib,
    ...
  }: let
    conch = inputs.conch.packages.${system}.default or null;
  in {
    packages = lib.optionalAttrs (conch != null) {
      inherit conch;
    };
  };
}
