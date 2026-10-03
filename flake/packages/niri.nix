{inputs, ...}: {
  perSystem = {
    system,
    lib,
    ...
  }: let
    niri-git = inputs.niri.packages.${system}.default or null;
  in {
    packages = lib.optionalAttrs (niri-git != null) {
      inherit niri-git;
    };
  };
}
