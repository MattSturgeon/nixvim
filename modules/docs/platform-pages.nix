{ lib, pkgs, ... }:
let
  evalPlatform =
    platformModule:
    lib.evalModules {
      modules = [
        platformModule
        { _module.check = false; }
        { _module.args.pkgs = lib.mkForce pkgs; }
      ];
    };

  mkPlatformPage =
    {
      title,
      module,
    }:
    {
      inherit title;
      options = lib.pipe module [
        evalPlatform
        (lib.getAttr "options")
        (x: builtins.removeAttrs x [ "_module" ])
        lib.options.optionAttrSetToDocList
        (builtins.filter (opt: opt.visible && !opt.internal))
        # TODO: transform declaration locations
      ];
    };
in
{
  meta.pages.platforms = {
    title = "Platform-specific options";
    showTitleOnPage = false;
    source = ../../docs/platforms/index.md;
    menuSection = "platforms";

    pages = {
      "nixos" = mkPlatformPage {
        title = "NixOS";
        module = ../../wrappers/modules/nixos.nix;
      };
      "home-manager" = mkPlatformPage {
        title = "home-manager";
        module = ../../wrappers/modules/hm.nix;
      };
      "nix-darwin" = mkPlatformPage {
        title = "nix-darwin";
        module = ../../wrappers/modules/darwin.nix;
      };
      "standalone" = {
        title = "Standalone Usage";
        showTitleOnPage = false;
        source = ../../docs/platforms/standalone.md;
      };
    };
  };

  # Define a menu section for platforms
  meta.menuSections.platforms = { };
}
