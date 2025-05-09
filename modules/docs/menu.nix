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
          ++ builtins.concatMap (pageToLines "") pages
          ++ [ "" ] # Blank line
        );
      pageToLines =
        indent: page:
        [ "${indent}- [${page.title}](${page.target})" ]
        ++ builtins.concatMap (pageToLines (indent + "  ")) (builtins.attrValues page.pages);
    in
    lib.mkMerge (builtins.concatMap sectionToLines sortedSections);
}
