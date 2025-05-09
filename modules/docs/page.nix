# Module implementing the `meta.page` submodule
{
  lib,
  config,
  pageStack,
  parentOptions,
  renderMarkdown,
  ...
}:
let
  inherit (config)
    optionPredicate
    ;

  drvName = lib.replaceStrings [ "/" ] [ "-" ] config.target;

  preamble = lib.concatMapStrings (para: para + "\n\n") (
    lib.optional (config.showTitleOnPage && config.title != "") config.title
    ++ lib.optional (config.text != null) config.text
  );

  childHasOption =
    opt: builtins.any (page: builtins.elem opt page.options) (builtins.attrValues config.pages);
  optionsOnThisPage = builtins.filter (opt: !childHasOption opt) config.options;

  commonOptionLoc =
    let
      locs = builtins.map (opt: opt.loc) config.options;
      nul = builtins.head locs;
      list = lib.lists.drop 1 locs;
      result = builtins.foldl' lib.lists.commonPrefix nul list;
    in
    if config.options == [ ] then [ ] else result;
in
{
  options = {
    target = lib.mkOption {
      type = lib.types.str;
      # TODO: escape path elements and/or add `.md` to the end (?)
      # TODO: set to "" when there is no page being rendered
      default = lib.concatStringsSep "/" pageStack;
      defaultText = lib.literalMD "the attribute path coerced to a filepath";
      description = ''
        The page's file name, i.e. the menu target.
      '';
    };
    title = lib.mkOption {
      type = lib.types.str;
      default =
        if commonOptionLoc == [ ] then
          # TODO: do some additional processing
          # e.g. basename, strip suffix, capitalise
          config.target
        else
          # TODO: should this escape markdown chars?
          lib.showOption commonOptionLoc;
      defaultText = lib.literalMD ''
        If this page or its sub-pages have options, then the common prefix of the option `loc`.
        Otherwise, the page's `target` is used.
      '';
      description = ''
        A title to include at the start of the page.
      '';
    };
    showTitleOnPage = lib.mkOption {
      type = lib.types.bool;
      default = true;
      example = false;
      description = ''
        Whether to render `title` on the page, before `text` and `source`.

        Even when disabled, `title` is still used for the page's menu item.
      '';
    };
    text = lib.mkOption {
      type = with lib.types; nullOr lines;
      default = null;
      description = ''
        Markdown text to include at the start of the page.
      '';
    };
    source = lib.mkOption {
      type = with lib.types; nullOr path;
      default = null;
      description = ''
        A markdown file to include after the `description`, at the start of the page.
      '';
    };
    # Recursive sub-submodule
    pages = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule [
          ./page.nix
          (
            { name, ... }:
            {
              _module.args = {
                pageStack = pageStack ++ [ name ];
                parentOptions = config.options;
                inherit renderMarkdown;
              };
            }
          )
        ]
      );
      default = { };
      description = ''
        Set of sub-pages nested below this page.
      '';
      visible = "shallow";
    };
    # Options for options
    optionPredicate = lib.mkOption {
      type = with lib.types; nullOr (functionTo bool);
      default = null;
      description = ''
        A function that returns whether an option should be included on this page.

        Should return true if the option is owned by this page or a sub-page.

        If defined, `optionPredicate` will be used to automatically populate `options`,
        by filtering the parent pages's options. Or by filtering the top-level options
        if there is no parent page.
      '';
    };
    options = lib.mkOption {
      type = with lib.types; listOf raw;
      default = [ ];
      description = ''
        A list of option doc templates, as returned by `lib.optionAttrSetToDocList`.

        Includes all options to include on this page or one of its sub-pages.
      '';
      internal = true;
    };
    optionsJSON = lib.mkOption {
      type = with lib.types; nullOr path;
      default = null;
      description = ''
        `options.json` file, as expected by `nixos-render-docs`.
      '';
      internal = true;
    };
    markdown = lib.mkOption {
      type = with lib.types; nullOr path;
      default = null;
      description = ''
        Markdown render of this page.
      '';
      internal = true;
    };
  };

  config = {
    options = lib.mkIf (optionPredicate != null) (builtins.filter optionPredicate parentOptions);
    optionsJSON = lib.mkIf (optionsOnThisPage != [ ]) (
      lib.pipe optionsOnThisPage [
        (builtins.map (opt: {
          inherit (opt) name;
          value = builtins.removeAttrs opt [
            "name"
            "visible"
            "internal"
          ];
        }))
        builtins.listToAttrs
        builtins.toJSON
        builtins.unsafeDiscardStringContext
        (builtins.toFile "options-${drvName}.json")
      ]
    );
    markdown =
      if preamble == "" && optionsOnThisPage == [ ] then
        lib.mkIf (config.source != null) config.source
      else
        renderMarkdown {
          name = drvName;
          text = preamble;
          inherit (config) source optionsJSON;
        };
  };
}
