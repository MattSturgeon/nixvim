{ lib, config, ... }:
{
  options.meta.menuSections = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule ./menu-section.nix);
    description = ''
      Menu sections that pages can be added to.
    '';
  };

  options.docs.menu = lib.mkOption {
    type = lib.types.lines;
    description = ''
      Docs menu
    '';
  };

  config.meta.menuSections = {
    before = {
      order = 50;
    };
    main = { };
    after = {
      order = 2000;
    };
  };

  config.docs.menu =
    let
      sortedSections = lib.pipe config.meta.menuSections [
        (builtins.mapAttrs (name: section: section // { inherit name; }))
        builtins.attrValues
        (lib.lists.sortOn (section: section.order))
      ];
      pagesBySection = builtins.groupBy (page: page.menuSection) (builtins.attrValues config.meta.pages);
      sectionToLines =
        section:
        let
          pages = pagesBySection.${section.name} or [ ];
        in
        lib.optionals (pages != [ ]) (
          [ "# ${section.title}" ]
          ++ [ "" ] # Blank line
          ++ builtins.concatMap (pageToLines "" null) pages
          ++ [ "" ] # Blank line
        );
      pageToLines =
        indent: parent: page:
        let
          prefix = lib.optionalString (parent ? title) (parent.title + ".");
          title = lib.strings.removePrefix prefix page.title;
        in
        [ "${indent}- [${title}](${page.target})" ]
        ++ builtins.concatMap (pageToLines (indent + "  ") page) (builtins.attrValues page.pages);
    in
    lib.mkMerge (builtins.concatMap sectionToLines sortedSections);

  # Add the menu to the markdown source
  config.docs.src."SUMMARY.md".text = config.docs.menu;
}
