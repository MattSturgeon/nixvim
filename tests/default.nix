{
  # By default, import nixpkgs from flake.lock
  nixpkgs ?
    let
      json = builtins.fromJSON (builtins.readFile ../flake.lock);
      lock = json.nodes.nixpkgs.locked;
    in
    fetchTarball {
      url =
        assert lock.type == "github";
        "https://github.com/${lock.owner}/${lock.repo}/archive/${lock.rev}.tar.gz";
      sha256 = lock.narHash;
    },
  pkgs ? import nixpkgs { },
  pkgsUnfree ? import nixpkgs { config.allowUnfree = true; },
  lib ? pkgs.lib,
  helpers ? import ../lib/helpers.nix {
    inherit pkgs lib;
    _nixvimTests = true;
  },
  mkTestDerivationFromNixvimModule ?
    (import ../lib/tests.nix { inherit pkgs lib; }).mkTestDerivationFromNixvimModule,
}:
let
  fetchTests = import ./fetch-tests.nix { inherit pkgs lib helpers; };

  mkTest =
    { name, module }:
    {
      inherit name;
      path = mkTestDerivationFromNixvimModule {
        inherit name module;
        pkgs = pkgsUnfree;
      };
    };

  # List of files containing configurations
  testFiles = fetchTests ./test-sources;

  exampleFiles = {
    name = "examples";
    modules =
      let
        config = import ../example.nix { inherit pkgs; };
      in
      [
        {
          name = "main";
          module = builtins.removeAttrs config.programs.nixvim [
            # This is not available to standalone modules, only HM & NixOS Modules
            "enable"
            # This is purely an example, it does not reflect a real usage
            "extraConfigLua"
            "extraConfigVim"
          ];
        }
      ];
  };
in
# We attempt to build & execute all configurations
lib.pipe (testFiles ++ [ exampleFiles ]) [
  (builtins.map (file: {
    inherit (file) name;
    path = pkgs.linkFarm file.name (builtins.map mkTest file.modules);
  }))
  (pkgs.linkFarm "tests")
]
