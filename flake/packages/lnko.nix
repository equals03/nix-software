{lib, ...}: let
  package = {
    lib,
    stdenvNoCC,
    fetchFromGitHub,
    lua5_4,
    makeWrapper,
    diffutils,
  }: let
    lua = lua5_4.withPackages (ps: [
      ps.luafilesystem
    ]);
  in
    stdenvNoCC.mkDerivation rec {
      pname = "lnko";
      version = "0.2.3";

      src = fetchFromGitHub {
        owner = "luanvil";
        repo = "lnko";
        rev = "v${version}";

        hash = "sha256-8kskzxgdSunrcaDIzUjGQgDZ5sz9Onr46nTNZNv+neg=";
      };

      nativeBuildInputs = [
        makeWrapper
      ];

      installPhase = ''
        runHook preInstall

        mkdir -p $out/bin $out/share/lua/lnko

        cp -r lnko $out/share/lua/
        install -Dm755 bin/lnko.lua $out/bin/lnko

        wrapProgram $out/bin/lnko \
          --set LUA_PATH "$out/share/lua/?.lua;$out/share/lua/?/init.lua;;" \
          --prefix PATH : ${lib.makeBinPath [diffutils lua]}

        runHook postInstall
      '';

      meta = {
        description = "Simple stow-like dotfile linker";
        homepage = "https://github.com/luanvil/lnko";
        license = lib.licenses.gpl3Only;
        mainProgram = "lnko";
        maintainers = [];

        platforms = lib.platforms.unix;

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
    lnko = pkgs.callPackage package {};
  in {
    packages = lib.optionalAttrs (builtins.elem system lnko.meta.platforms) {
      inherit lnko;
    };
  };
}
