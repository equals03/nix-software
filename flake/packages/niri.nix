{lib, ...}: let
  libdisplay-info3 = {
    lib,
    stdenv,
    buildPackages,
    fetchFromGitLab,
    meson,
    pkg-config,
    ninja,
    python3,
    hwdata,
    v4l-utils,
  }:
    stdenv.mkDerivation (finalAttrs: {
      pname = "libdisplay-info";
      version = "0.3.0";

      src = fetchFromGitLab {
        domain = "gitlab.freedesktop.org";
        owner = "emersion";
        repo = "libdisplay-info";
        rev = finalAttrs.version;
        sha256 = "sha256-nXf2KGovNKvcchlHlzKBkAOeySMJXgxMpbi5z9gLrdc=";
      };

      depsBuildBuild = [pkg-config];
      nativeBuildInputs =
        [
          meson
          pkg-config
          ninja
          hwdata
          python3
        ]
        ++ lib.optionals (stdenv.hostPlatform.emulatorAvailable buildPackages) [
          # Only used for tests, which we cannot run without an emulator
          v4l-utils
        ];

      postPatch = ''
        patchShebangs tool/gen-search-table.py
      '';

      meta = {
        description = "EDID and DisplayID library";
        mainProgram = "di-edid-decode";
        homepage = "https://gitlab.freedesktop.org/emersion/libdisplay-info";
        license = lib.licenses.mit;
        platforms = lib.platforms.linux ++ lib.platforms.freebsd;
        maintainers = with lib.maintainers; [pedrohlc];
      };
    });

  package = {
    lib,
    dbus,
    eudev,
    fetchFromGitHub,
    installShellFiles,
    libdisplay-info,
    libglvnd,
    libinput,
    libxkbcommon,
    libgbm,
    versionCheckHook,
    pango,
    pipewire,
    pkg-config,
    rustPlatform,
    seatd,
    stdenv,
    systemd,
    wayland,
    withDbus ? true,
    withDinit ? false,
    withScreencastSupport ? true,
    withSystemd ? true,
  }:
    rustPlatform.buildRustPackage (finalAttrs: {
      pname = "niri";
      version = "26.04";

      src = fetchFromGitHub {
        owner = "niri-wm";
        repo = "niri";
        tag = "v${finalAttrs.version}";
        hash = "sha256-ehSMsSpE+0k8r+2Vseu8kangsYxToZv3vinynsDp9zs=";
      };

      outputs = [
        "out"
        "doc"
      ];

      postPatch = ''
        patchShebangs resources/niri-session
        substituteInPlace resources/niri.service \
          --replace-fail 'ExecStart=niri' "ExecStart=$out/bin/niri"
      '';

      cargoHash = "sha256-gfnalA3qI3a9h3PvsxgQLCrzapfjLLkxhTMJpwRh+ro=";

      strictDeps = true;

      nativeBuildInputs = [
        installShellFiles
        pkg-config
        rustPlatform.bindgenHook
      ];

      buildInputs =
        [
          libdisplay-info
          libglvnd # For libEGL
          libinput
          libxkbcommon
          libgbm
          pango
          seatd
          wayland # For libwayland-client
        ]
        ++ lib.optional (withDbus || withScreencastSupport || withSystemd) dbus
        ++ lib.optional withScreencastSupport pipewire
        ++ lib.optional withSystemd systemd # Includes libudev
        ++ lib.optional (!withSystemd) eudev; # Use an alternative libudev implementation when building w/o systemd

      buildFeatures =
        lib.optional withDbus "dbus"
        ++ lib.optional withDinit "dinit"
        ++ lib.optional withScreencastSupport "xdp-gnome-screencast"
        ++ lib.optional withSystemd "systemd";
      buildNoDefaultFeatures = true;

      postInstall =
        ''
          install -Dm0644 README.md resources/default-config.kdl -t $doc/share/doc/niri
          mv docs/wiki $doc/share/doc/niri/wiki

          install -Dm0644 resources/niri.desktop -t $out/share/wayland-sessions
        ''
        + lib.optionalString withDbus ''
          install -Dm0644 resources/niri-portals.conf -t $out/share/xdg-desktop-portal
        ''
        + lib.optionalString (withSystemd || withDinit) ''
          install -Dm0755 resources/niri-session -t $out/bin
        ''
        + lib.optionalString withSystemd ''
          install -Dm0644 resources/niri{-shutdown.target,.service} -t $out/lib/systemd/user
        ''
        + lib.optionalString withDinit ''
          install -Dm0644 resources/dinit/niri{-shutdown,} -t $out/lib/dinit.d/user
        ''
        + lib.optionalString (stdenv.buildPlatform.canExecute stdenv.hostPlatform) ''
          installShellCompletion --cmd $pname \
            --bash <($out/bin/niri completions bash) \
            --fish <($out/bin/niri completions fish) \
            --zsh <($out/bin/niri completions zsh)
        '';

      env = {
        # Force linking with libEGL and libwayland-client
        # so they can be discovered by `dlopen()`
        RUSTFLAGS = toString (
          map (arg: "-C link-arg=" + arg) [
            "-Wl,--push-state,--no-as-needed"
            "-lEGL"
            "-lwayland-client"
            "-Wl,--pop-state"
          ]
        );

        # Upstream recommends setting the commit hash manually when in a
        # build environment where the Git repository is unavailable.
        # See https://github.com/niri-wm/niri/wiki/Packaging-niri#version-string
        NIRI_BUILD_COMMIT = "Nixpkgs";
      };

      # its a release - im happy to assume the checks were already done
      doCheck = false;

      nativeInstallCheckInputs = [versionCheckHook];
      doInstallCheck = true;

      passthru = {
        providedSessions = ["niri"];
      };

      meta = {
        description = "Scrollable-tiling Wayland compositor";
        homepage = "https://github.com/niri-wm/niri";
        changelog = "https://github.com/niri-wm/niri/releases/tag/v${finalAttrs.version}";
        license = lib.licenses.gpl3Only;
        mainProgram = "niri";
        platforms = lib.platforms.linux;
        maintainers = [];

        # enroll in the custom 'update-packages' script
        update.enable = true;
      };
    });
in {
  perSystem = {
    pkgs,
    system,
    ...
  }: let
    libdisplay-info = pkgs.callPackage libdisplay-info3 {};
    niri = pkgs.callPackage package {inherit libdisplay-info;};
  in {
    packages = lib.optionalAttrs (builtins.elem system niri.meta.platforms) {
      inherit niri;
    };
  };
}
