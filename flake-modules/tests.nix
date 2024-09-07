{ self, ... }:
{
  perSystem =
    {
      self',
      pkgs,
      pkgsUnfree,
      system,
      ...
    }:
    let
      inherit (self'.legacyPackages.lib) helpers makeNixvimWithModule;
      inherit (self'.legacyPackages.lib.check) mkTestDerivationFromNvim mkTestDerivationFromNixvimModule;
      evaluatedNixvim = helpers.modules.evalNixvim { check = false; };
    in
    {
      checks = {
        extra-args-tests = import ../tests/extra-args.nix { inherit pkgs makeNixvimWithModule; };

        extend = import ../tests/extend.nix { inherit pkgs makeNixvimWithModule; };

        extra-files = import ../tests/extra-files.nix { inherit pkgs makeNixvimWithModule; };

        enable-except-in-tests = import ../tests/enable-except-in-tests.nix {
          inherit pkgs makeNixvimWithModule mkTestDerivationFromNixvimModule;
        };

        failing-tests = pkgs.callPackage ../tests/failing-tests.nix {
          inherit mkTestDerivationFromNixvimModule;
        };

        no-flake = import ../tests/no-flake.nix {
          inherit system mkTestDerivationFromNvim;
          nixvim = "${self}";
        };

        lib-tests = import ../tests/lib-tests.nix {
          inherit pkgs helpers;
          inherit (pkgs) lib;
        };

        maintainers = import ../tests/maintainers.nix { inherit pkgs; };

        generated = pkgs.callPackage ../tests/generated.nix { };

        package-options = pkgs.callPackage ../tests/package-options.nix { inherit evaluatedNixvim; };
      } // import ../tests { inherit pkgs pkgsUnfree helpers; };
    };
}
