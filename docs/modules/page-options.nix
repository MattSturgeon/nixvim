{
  lib,
  config,
  options,
  ...
}:
{
  options = {
    loc = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "Page's location in the menu.";
      readOnly = true;
    };
    target = lib.mkOption {
      type = lib.types.str;
      default = lib.optionalString config.hasContent (lib.concatStringsSep "/" config.loc);
      defaultText = lib.literalMD ''
        `""` if page has no content, otherwise a filepath derived from the page's `loc`.
      '';
      description = "Where to render content and link menu entries.";
    };
    title = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Page's heading title.";
    };
    text = lib.mkOption {
      type = lib.types.nullOr lib.types.lines;
      default = null;
      description = "Optional markdown text to include after the title.";
    };
    source = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Optional markdown file to include after the title.";
    };
    libFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Optional nix file to scan for RFC145 doc comments.";
    };
    libLoc = lib.mkOption {
      type = lib.types.nullOr (lib.types.listOf lib.types.str);
      default =
        if config.libFile != null && builtins.head config.loc == "lib" then
          builtins.tail config.loc
        else
          null;
      defaultText = lib.literalMD ''
        `tail loc` if `libFile != null` and `head loc == "lib"`, otherwise `null`.
      '';
      description = ''
        Optional attrpath where functions are defined. Required when using `libFile`.

        Will be used to define the `category` provided to `nixdoc`.

        Will scan `lib` for attribute locations in the functions set at this attrpath.

        Used in conjunction with `nix`.
      '';
    };
    options = lib.mkOption {
      type = lib.types.nullOr lib.types.raw;
      default = null;
      apply = opts: if builtins.isAttrs opts then lib.options.optionAttrSetToDocList opts else opts;
      description = ''
        Optional set of options or list of option docs-templates.

        If an attrset is provided, it will be coerced using `lib.options.optionAttrSetToDocList`.
      '';
    };
    children = lib.mkOption {
      type = lib.types.ints.unsigned;
      description = ''
        The number of child pages.
      '';
      readOnly = true;
    };
    hasContent = lib.mkOption {
      type = lib.types.bool;
      description = ''
        Whether this page has any docs content.

        When `false`, this page represents an _empty_ menu entry.
      '';
      readOnly = true;
    };
  };

  config.source = lib.mkIf (config.text != null) (
    lib.mkDerivedConfig options.text (
      builtins.toFile "docs-${lib.attrsets.showAttrPath config.loc}-text.md"
    )
  );

  config.hasContent = builtins.any (name: config.${name} != null) [
    "source" # markdown
    "libFile" # doc-comments
    "options" # module options
  ];
}
