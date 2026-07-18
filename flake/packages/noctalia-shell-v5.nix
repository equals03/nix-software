{inputs, ...}: {
  perSystem = {
    system,
    lib,
    ...
  }: let
    noctalia-shell-v5 = inputs.noctalia.packages.${system}.default or null;
  in {
    packages = lib.optionalAttrs (noctalia-shell-v5 != null) {
      inherit noctalia-shell-v5;
    };
  };
}
