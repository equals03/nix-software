{lib, ...}: let
  package = {
    fetchFromGitHub,
    lib,
    bash,
    linux-pam,
    rustPlatform,
    systemdMinimal,
    versionCheckHook,
    nixosTests,
  }:
    rustPlatform.buildRustPackage (finalAttrs: {
      pname = "lemurs";
      version = "0.4.0-unstable-${finalAttrs.src.rev}";

      src = fetchFromGitHub {
        owner = "coastalwhite";
        repo = "lemurs";
        rev = "22091b2";
        hash = "sha256-JAJZZE/q8eoxl4k10v9NhMdvS0jw+oA/Jw/lPs7UUkU=";
      };

      cargoHash = "sha256-7mSzw1pkejMeEnvYzTaleR7wJtPIIHlw7/Rm9GqTWjQ=";

      buildInputs = [
        bash
        linux-pam
        systemdMinimal
      ];

      passthru.tests = {
        inherit
          (nixosTests)
          lemurs
          lemurs-wayland
          lemurs-wayland-script
          lemurs-xorg
          lemurs-xorg-script
          ;
      };

      meta = {
        description = "Customizable TUI display/login manager written in Rust";
        homepage = "https://github.com/coastalwhite/lemurs";
        license = with lib.licenses; [
          asl20
          mit
        ];
        maintainers = [];
        mainProgram = "lemurs";
      };
    });
in {
  perSystem = {
    pkgs,
    system,
    ...
  }: let
    lemurs = pkgs.callPackage package {};
  in {
    packages = lib.optionalAttrs (builtins.elem system lemurs.meta.platforms) {
      inherit lemurs;
    };
  };
}
