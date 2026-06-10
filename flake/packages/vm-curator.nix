{lib, ...}: let
  package = {
    lib,
    fetchFromGitHub,
    rustPlatform,
    pkg-config,
    openssl,
    udev,
  }:
    rustPlatform.buildRustPackage rec {
      pname = "vm-curator";
      version = "1.1.0";

      src = fetchFromGitHub {
        owner = "mroboff";
        repo = "vm-curator";
        rev = "v${version}";
        # replace this hash with the actual one after first build
        hash = "sha256-7XUUNUHe74uYMzIf7n98H2z4pq4RguBXFtpznrggtGk=";
      };

      cargoLock = {
        lockFile = "${src}/Cargo.lock";
      };

      nativeBuildInputs = [pkg-config];

      buildInputs = [
        openssl
        udev
      ];

      # its a release - im happy to assume the checks were already done
      doCheck = false;

      meta = with lib; {
        description = "Fast and friendly Rust TUI for managing desktop QEMU/KVM virtual machines";
        homepage = "https://github.com/mroboff/vm-curator";
        license = licenses.mit; # project is MIT-licensed
        platforms = platforms.linux;
        mainProgram = "vm-curator";
        maintainers = [];

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
    vm-curator = pkgs.callPackage package {};
  in {
    packages = lib.optionalAttrs (builtins.elem system vm-curator.meta.platforms) {
      inherit vm-curator;
    };
  };
}
