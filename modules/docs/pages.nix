{ lib, options, ... }:
let
  docOptions = lib.pipe options [
    (x: builtins.removeAttrs x [ "_module" ])
    lib.options.optionAttrSetToDocList
    (builtins.filter (opt: opt.visible && !opt.internal))
    # TODO: transform declaration locations
  ];
in
{
  options.meta.pages = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule (lib.modules.importApply ./page.nix docOptions));
    default = { };
    description = ''
      Set of pages to include in the docs;
    '';
  };
}
