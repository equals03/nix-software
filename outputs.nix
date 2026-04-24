{
  nixpkgs,
  flake-parts,
  devshell,
  import-tree,
  nix-pax,
  treefmt-nix,
  ...
} @ inputs:
flake-parts.lib.mkFlake {
  inherit inputs;
} ({lib, ...}: let
  prune-default = paths: let
    defaultDirs = map dirOf (builtins.filter (p: baseNameOf p == "default.nix") paths);
  in
    builtins.filter (p:
      baseNameOf p
      == "default.nix"
      || !(builtins.any (d: lib.path.hasPrefix d (dirOf p)) defaultDirs))
    paths;

  modules = lib.pipe import-tree [
    (i: i.addPath ./flake)
    (i: i.withLib lib)
    (i:
      i.addAPI {
        pruned = self: {imports = prune-default self.files;};
      })
  ];
in {
  imports = [
    flake-parts.flakeModules.modules

    nix-pax.flakeModule

    treefmt-nix.flakeModule
    devshell.flakeModule

    modules.pruned
  ];

  config = {
    debug = false;

    systems = [
      "x86_64-linux"
    ];

    perSystem = {system, ...}: {
      config._module.args.pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      #checks.all-packages-build = self.apps.${system}.build-all-packages.program;
    };
  };
})
