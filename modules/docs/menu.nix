{ lib, ... }:
{
  options.meta.menuSections = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          # TODO
        };
      }
    );
    description = ''
      Menu sections that pages can be added to.
    '';
  };

  config.meta.menuSections = {
    before = { };
    main = { };
    after = { };
  };
}
