_: let
  module = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.services.nmlinkd;
  in {
    options.services.nmlinkd = {
      enable = lib.mkEnableOption "nmlinkd NetworkManager D-Bus compatibility service";

      package = lib.mkPackageOption pkgs "nmlinkd" {};
    };

    config = lib.mkIf cfg.enable {
      assertions = [
        {
          assertion = !config.networking.networkmanager.enable;
          message = ''
            services.nmlinkd.enable conflicts with services.networkmanager.enable.

            nmlinkd emulates NetworkManager's D-Bus API and must own
            org.freedesktop.NetworkManager, so NetworkManager must be disabled.
          '';
        }
      ];

      environment.systemPackages = [cfg.package];

      services.dbus.packages = [cfg.package];
      systemd.packages = [cfg.package];

      systemd.services.nmlinkd.wantedBy = ["multi-user.target"];
    };
  };
in {
  flake.nixosModules.nmlinkd = module;
}
