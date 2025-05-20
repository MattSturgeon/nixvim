# This module represents a node in a tree of pages.
# It is recursive, in that its freeformType is another submodule of this module.
{
  lib,
  prefix,
  name,
  config,
  options,
  ...
}:
let
  optionNames = builtins.attrNames options;
  children = lib.pipe config [
    (lib.flip builtins.removeAttrs optionNames)
    builtins.attrNames
    builtins.length
  ];
  loc = prefix ++ [ name ];
in
{
  freeformType = lib.types.attrsOf (
    lib.types.submoduleWith {
      specialArgs.prefix = prefix ++ [ name ];
      modules = [ ./page.nix ];
    }
    // {
      description = "page submodule";
      descriptionClass = "noun";
      # Alternative to `visible = "shallow"`, avoid inf-recursion when collecting options for docs
      getSubOptions = _: { };
    }
  );

  # Ensure the `prefix` arg exists
  # Usually shadowed by `specialArgs.prefix`
  config._module.args.prefix = [ ];

  # The _page option contains options for this page node
  options._page = lib.mkOption {
    type = lib.types.submodule [
      ./page-options.nix
      { inherit loc children; }
    ];
    default = { };
    description = ''
      Page data and metadata.
    '';
  };
}
