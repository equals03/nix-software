{
  outputs = inputs: import ./outputs.nix inputs;

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    systems.url = "github:nix-systems/default-linux";

    # software
    conch.url = "github:equals03/conch";
    cursor.url = "github:tylergets/cursor-flake";
    codex-cli.url = "github:sadjow/codex-cli-nix";

    hunk = {
      url = "github:modem-dev/hunk";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.bun2nix.inputs.systems.follows = "systems";
    };

    pi = {
      url = "github:rbright/nix-pi-agent";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser.url = "github:youwen5/zen-browser-flake";

    # infrastructure
    flake-parts.url = "github:hercules-ci/flake-parts";
    nix-pax.url = "github:equals03/nix-pax?ref=feat/additional-aliases";

    import-tree.url = "github:vic/import-tree";

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
