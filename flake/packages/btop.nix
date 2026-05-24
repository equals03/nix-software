{
  perSystem = {pkgs, ...}: let
    btop = pkgs.btop.override {
      rocmSupport = true;
      cudaSupport = true;
    };
  in {
    packages = {
      inherit btop;
    };
  };
}
