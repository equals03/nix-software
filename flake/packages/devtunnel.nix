{lib, ...}: let
  package = {
    lib,
    stdenvNoCC,
    fetchurl,
    buildFHSEnv,
    icu,
    openssl,
    zlib,
    krb5,
    curl,
    gcc,
  }: let
    version = "1.0.1972+07cc55c789";
    devtunnel-unwrapped = stdenvNoCC.mkDerivation {
      pname = "devtunnel-unwrapped";
      inherit version;

      src = fetchurl {
        url = "https://tunnelsassetsprod.blob.core.windows.net/cli/${version}/linux-x64-devtunnel";
        hash = "sha256-Y4DT5UyB5+JUGQC+w9TyeF2/gfF82B7/vVTZjxGodLk=";
      };

      dontUnpack = true;
      dontPatchELF = true;
      dontStrip = true;

      installPhase = ''
        runHook preInstall

        install -Dm755 "$src" "$out/bin/devtunnel"

        runHook postInstall
      '';
    };
  in
    buildFHSEnv {
      name = "devtunnel";

      targetPkgs = _pkgs: [
        icu
        openssl
        zlib
        krb5
        curl
        gcc.cc.lib
      ];

      runScript = "${devtunnel-unwrapped}/bin/devtunnel";

      meta = with lib; {
        description = "Microsoft Dev Tunnels command-line interface";
        homepage = "https://learn.microsoft.com/azure/developer/dev-tunnels/";
        license = licenses.unfree;
        platforms = platforms.unix;
        sourceProvenance = with sourceTypes; [
          binaryNativeCode
        ];
        mainProgram = "devtunnel";
      };
    };
in {
  perSystem = {
    pkgs,
    system,
    ...
  }: let
    devtunnel = pkgs.callPackage package {};
  in {
    packages = lib.optionalAttrs (builtins.elem system devtunnel.meta.platforms) {
      inherit devtunnel;
    };
  };
}
