{inputs, ...}: {
  perSystem = {
    system,
    lib,
    ...
  }: let
    xwayland-satellite-git = inputs.xwayland-satellite.packages.${system}.default or null;
  in {
    packages = lib.optionalAttrs (xwayland-satellite-git != null) {
      inherit xwayland-satellite-git;
    };
  };
}
