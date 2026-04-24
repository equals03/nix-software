{
  self,
  lib,
  ...
}: let
  overlay-with-system = overlay: final: prev: let
    inherit (prev.stdenv.hostPlatform) system;
  in
    overlay {inherit system final prev;};

  version-check = mine: theirs: let
    quiet = mine.meta.quiet or false;
    older = lib.versionOlder (lib.getVersion mine) (lib.getVersion theirs);
  in
    if quiet || !older
    then mine
    else lib.warn "Potentially out of date package: `${mine.name}` < ${theirs.name}.";
in {
  # all the packages from my flake
  flake.overlays.packages = overlay-with-system (
    {
      system,
      prev,
      ...
    }: let
      packages = self.packages.${system} or {};
    in
      lib.mapAttrs (name: mine: version-check mine (prev.${name} or mine)) packages
  );
}
