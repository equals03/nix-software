{inputs, ...}: {
  perSystem = {
    system,
    pkgs,
    lib,
    ...
  }: let
    pi = inputs.pi.packages.${system}.pi or null;
  in {
    packages = lib.optionalAttrs (pi != null) {
      pi = pi.override {
        extraRuntimePackages = with pkgs; [
          fd
        ];
      };
    };
  };
}
