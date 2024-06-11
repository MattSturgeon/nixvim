{
  pkgs ? import <nixpkgs> { },
  lib ? pkgs.lib,
  libName ? "helpers",
  targetLib ? import ../lib/helpers.nix {
    inherit pkgs lib;
    _nixvimTests = false;
  },
  libsets ? lib.importJSON ./lib-function-sets.json,
  # pathPrefix will be substituted for urlPrefix in links
  pathPrefix ? ../.,
  urlPrefix ? "https://github.com/nix-community/nixvim/blob/${revision}",
  revision ? "main", # TODO
  ...
}:
with builtins;
let

  libDefPos =
    prefix: set:
    concatMap (
      name:
      [
        {
          name = concatStringsSep "." (prefix ++ [ name ]);
          location = unsafeGetAttrPos name set;
        }
      ]
      ++ lib.optionals (length prefix == 0 && isAttrs set.${name}) (
        libDefPos (prefix ++ [ name ]) set.${name}
      )
    ) (attrNames set);

  getLibset =
    toplib:
    lib.trivial.pipe libsets [
      attrNames
      (map (subset: {
        inherit subset;
        functions = libDefPos [ ] toplib.${subset};
      }))
    ];

  getLibsetFns =
    { subset, functions }:
    map (fn: {
      name = "${libName}.${subset}.${fn.name}";
      loc = fn.location;
    }) functions;

  removeFilenamePrefix =
    prefix: filename:
    let
      prefixLen = (stringLength prefix) + 1; # +1 to remove the leading /
      filenameLen = stringLength filename;
      substr = substring prefixLen filenameLen filename;
    in
    substr;

  relativeLocs = lib.trivial.pipe targetLib [
    getLibset
    (map getLibsetFns)
    lib.lists.flatten
    (filter (elem: elem.loc != null))
    (map (
      { name, loc }:
      {
        inherit name;
        loc = loc // {
          # FIXME we want to remove helpers path prefix, not pkgs.path
          # FIXME use lib.path.removePrefix or lib.string.removePrefix depending on whether value.file is a path
          file = removeFilenamePrefix (toString pkgs.path) loc.file;
        };
      }
    ))
  ];

  sanitizeId = replaceStrings [ "'" ] [ "-prime" ];

  jsonLocs = listToAttrs (
    map (
      { name, loc }:
      {
        name = sanitizeId name;
        value =
          let
            text = "${loc.file}:${toString loc.line}";
            url = "${urlPrefix}/${loc.file}#L${toString loc.line}";
          in
          "[${text}](${url}) in `<nixvim>`";
      }
    ) relativeLocs
  );

in
pkgs.writeText "locations.json" (toJSON jsonLocs)
