{
  lib,
  config,
  options,
  pkgs,
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
        ./page.nix
        (
          {
            lib,
            name,
            config,
            ...
          }:
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

            config._module.args = {
              pageStack = [ name ];
              parentOptions = docOptions;
              renderMarkdown = pkgs.callPackage ./render-page-md.nix;
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
