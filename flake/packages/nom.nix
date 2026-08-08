{
  perSystem = {pkgs, ...}: {
    packages = {
      inherit (pkgs) nix-output-monitor;
    };
  };
}
