{inputs, ...}: {
  perSystem = {
    system,
    lib,
    ...
  }: let
    hunk = inputs.hunk.packages.${system}.default or null;
  in {
    packages = lib.optionalAttrs (hunk != null) {
      inherit hunk;
    };
  };
}
