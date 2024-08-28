{ self, ... }:
{
  perSystem =
    {
      pkgs,
      pkgsUnfree,
      system,
      helpers,
      makeNixvimWithModule,
      ...
    }:
    {
      checks = {
        extra-args-tests = import ../tests/extra-args.nix {
          inherit pkgs;
          inherit makeNixvimWithModule;
        };

        extend = import ../tests/extend.nix { inherit pkgs makeNixvimWithModule; };

        extra-files = import ../tests/extra-files.nix { inherit pkgs makeNixvimWithModule; };

        enable-except-in-tests = import ../tests/enable-except-in-tests.nix {
          inherit pkgs makeNixvimWithModule;
          inherit (self.lib.${system}.check) mkTestDerivationFromNixvimModule;
        };

        failing-tests = import ../tests/failing-tests.nix {
          inherit pkgs;
          inherit (self.lib.${system}.check) mkTestDerivationFromNixvimModule;
        };

        no-flake = import ../tests/no-flake.nix {
          inherit system;
          inherit (self.lib.${system}.check) mkTestDerivationFromNvim;
          nixvim = "${self}";
        };

        lib-tests = import ../tests/lib-tests.nix {
          inherit pkgs helpers;
          inherit (pkgs) lib;
        };

        maintainers = import ../tests/maintainers.nix { inherit pkgs; };

        generated = pkgs.callPackage ../tests/generated.nix { };

        tests =
          pkgs.runCommandNoCCLocal "tests"
            {
              testsSrc = ../tests;
              testList =
                builtins.attrNames
                  (import ../tests { inherit pkgs pkgsUnfree helpers; }).passthru.entries;
              nativeBuildInputs = [ pkgs.nix ];
            }
            ''
              for name in $testList; do
                echo "Building $name"
                nix-build "$testsSrc" --attr "passthru.entries.$name"
              done
              touch $out
            '';
      };
    };
}
