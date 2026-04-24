{inputs, ...}: {
  perSystem = {
    system,
    lib,
    ...
  }: let
    xwayland-satellite = inputs.xwayland-satellite.packages.${system}.xwayland-satellite or null;
  in {
    packages = lib.optionalAttrs (xwayland-satellite != null) {
      inherit xwayland-satellite;
    };
  };
}
