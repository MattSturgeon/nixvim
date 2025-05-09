{
  lib,
  config,
  options,
  ...
}:
let
  docOptions = lib.pipe options [
    (x: builtins.removeAttrs x [ "_module" ])
    lib.options.optionAttrSetToDocList
    (builtins.filter (opt: opt.visible && !opt.internal))
    # TODO: transform declaration locations
  ];

  menuSectionType = lib.types.enum (builtins.attrNames config.meta.menuSections) // {
    description = "an attribute name defined in ${options.meta.menuSections}";
  };
in
{
  options.meta.pages = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule [
        (lib.modules.importApply ./page.nix docOptions)
        (
          { lib, config, ... }:
          {
            options.menuSection = lib.mkOption {
              type = menuSectionType;
              default = if config.options == [ ] then "main" else "options";
              defaultText = lib.literalMD ''
                `"options"` if this page has any options, otherwise `"main"`
              '';
              description = ''
                The name of the menu section where this page should go.
              '';
            };
          }
        )
      ]
    );
    default = { };
    description = ''
      Set of pages to include in the docs;
    '';
  };

  # Define a menu section for options
  config.meta.menuSections.options = { };
}
