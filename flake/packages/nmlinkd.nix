{lib, ...}: let
  package = {
    lib,
    fetchFromGitHub,
    rustPlatform,
  }:
    rustPlatform.buildRustPackage rec {
      pname = "nmlinkd";
      version = "0.2.0";

      src = fetchFromGitHub {
        owner = "SubZ69";
        repo = "nmlinkd";
        rev = "v${version}";
        hash = "sha256-pPcQg3yOaVVHqGueWJkQFf2r/Tod6+WeGKh+5oVSHT8=";
      };

      cargoHash = "sha256-7WeImD5LM/EhiDhRddsR4VPovRYtxryaocTwMTIeOzY=";

      # tests fail within the nix sandbox due to mutations
      # TODO: selectively exclude failing tests
      doCheck = false;

      postInstall = ''
        install -Dm644 dist/org.freedesktop.NetworkManager.conf \
          $out/share/dbus-1/system.d/org.freedesktop.NetworkManager.conf

        install -Dm644 dist/org.freedesktop.NetworkManager.service \
          $out/share/dbus-1/system-services/org.freedesktop.NetworkManager.service

        substituteInPlace $out/share/dbus-1/system-services/org.freedesktop.NetworkManager.service \
          --replace-fail "/usr/bin/nmlinkd" "$out/bin/nmlinkd"

        install -Dm644 dist/org.freedesktop.NetworkManager.policy \
          $out/share/polkit-1/actions/org.freedesktop.NetworkManager.policy

        install -Dm644 dist/nmlinkd.service \
          $out/lib/systemd/system/nmlinkd.service

        substituteInPlace $out/lib/systemd/system/nmlinkd.service \
          --replace-fail "/usr/bin/nmlinkd" "$out/bin/nmlinkd"
      '';

      meta = with lib; {
        description = "Native GNOME/KDE network indicator for systemd-networkd, iwd, dhcpcd. No NetworkManager required.";
        homepage = "https://github.com/SubZ69/nmlinkd";
        license = licenses.mit;
        mainProgram = "nmlinkd";
        maintainers = [];
        platforms = [
          "x86_64-linux"
          "aarch64-linux"
        ];

        # enroll in the custom 'update-packages' script
        update.enable = true;
      };
    };
in {
  perSystem = {
    pkgs,
    system,
    ...
  }: let
    nmlinkd = pkgs.callPackage package {};
  in {
    packages = lib.optionalAttrs (builtins.elem system nmlinkd.meta.platforms) {
      inherit nmlinkd;
    };
  };
}
