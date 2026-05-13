{lib, ...}: let
  package = {
    lib,
    fetchFromGitHub,
    rustPlatform,
  }:
    rustPlatform.buildRustPackage rec {
      pname = "nmlinkd";
      version = "0.2.1";

      src = fetchFromGitHub {
        owner = "SubZ69";
        repo = "nmlinkd";
        rev = "v${version}";
        hash = "sha256-c7wylhuqIkyG4A3j6dR0GG3GT1uZZUXgDb1ShWClyGo=";
      };

      cargoHash = "sha256-AAmGh4+PS31CjBB76yd44QOuQMxdTPXq9kn8iocHScA=";

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
