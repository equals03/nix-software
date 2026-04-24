{inputs, ...}: {
  perSystem = {
    system,
    lib,
    ...
  }: let
    work-trunk = inputs.work-trunk.packages.${system}.default or null;
  in {
    packages = lib.optionalAttrs (work-trunk != null) {
      inherit work-trunk;
    };
  };
}
