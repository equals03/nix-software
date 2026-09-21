{inputs, ...}: {
  perSystem = {
    system,
    lib,
    ...
  }: let
    niri = inputs.niri.packages.${system}.default or null;
  in {
    packages = lib.optionalAttrs (niri != null) {
      inherit niri;
    };
  };
}
