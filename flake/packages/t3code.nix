{inputs, ...}: {
  perSystem = {
    system,
    lib,
    ...
  }: let
    t3code = inputs.t3code.packages.${system}.default or null;
  in {
    packages = lib.optionalAttrs (t3code != null) {
      inherit t3code;
    };
  };
}
