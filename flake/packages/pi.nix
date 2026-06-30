{inputs, ...}: {
  perSystem = {
    system,
    lib,
    ...
  }: let
    pi = inputs.pi.packages.${system}.pi-agent or null;
  in {
    packages = lib.optionalAttrs (pi != null) {
      inherit pi;
    };
  };
}
