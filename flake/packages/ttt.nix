{inputs, ...}: {
  perSystem = {
    system,
    lib,
    ...
  }: let
    ttt = inputs.ttt.packages.${system}.default or null;
  in {
    packages = lib.optionalAttrs (ttt != null) {
      inherit ttt;
    };
  };
}
