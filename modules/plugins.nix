{ lib, options, ... }:
let
  inherit (builtins) readDir mapAttrs;
  inherit (lib.attrsets) genAttrs filterAttrs foldlAttrs;
  inherit (lib.lists) optional;
  by-name = ../plugins/by-name;
in
{
  imports =
    [ ../plugins ]
    ++ foldlAttrs (
      prev: name: type:
      prev ++ optional (type == "directory") (by-name + "/${name}")
    ) [ ] (readDir by-name);

  # Declare plugins and colorschemes pages
  config.meta.pages.options.pages = genAttrs [ "plugins" "colorschemes" ] (set: {
    optionPredicate = opt: lib.lists.hasPrefix [ set ] opt.loc;

    # Declare separate sub-pages for each plugin
    pages = lib.pipe options.${set} [
      (filterAttrs (_: opt: !lib.isOption opt))
      (mapAttrs (
        name: _: {
          optionPredicate = opt: lib.lists.hasPrefix [ set name ] opt.loc;
          # TODO: sub-pages for settings, etc?
          # TODO: description, etc
        }
      ))
    ];
  });
}
