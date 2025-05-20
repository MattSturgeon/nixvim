# Generates the documentation for library functions using nixdoc.
# See https://github.com/nix-community/nixdoc
{
  lib,
  runCommand,
  writers,
  nixdoc,
  nixvim,
  pageSpecs ? ./pages.nix,
}:

let
  pageConfiguration = lib.evalModules {
    modules = [
      pageSpecs
      {
        freeformType = lib.types.attrsOf (
          lib.types.submoduleWith {
            modules = [ ../modules/page.nix ];
          }
        );
      }
    ];
  };
  pages = pageConfiguration.config;

  # Collect all page nodes into a list of page entries
  collectPages =
    pages:
    builtins.concatMap (
      node:
      let
        children = builtins.removeAttrs node [ "_page" ];
      in
      lib.optional (node ? _page) node._page ++ lib.optionals (children != { }) (collectPages children)
    ) (builtins.attrValues pages);

  # Normalised page specs
  pageList = collectPages pages;
  pagesToRender = builtins.filter (page: page.hasContent) pageList;
in

runCommand "nixvim-lib-docs"
  {
    nativeBuildInputs = [
      nixdoc
    ];

    locations = writers.writeJSON "locations.json" (
      import ./function-locations.nix {
        inherit lib;
        rootPath = nixvim;
        functionSet = lib.extend nixvim.lib.overlay;
        pathsToScan = lib.pipe pageList [
          (builtins.catAttrs "libLoc")
          (builtins.filter (loc: loc != null))
        ];
        revision = nixvim.rev or "main";
      }
    );

    passthru.config = pageConfiguration;

    passthru.menu = import ./menu.nix {
      inherit lib pages;
    };

    passthru.pages = builtins.listToAttrs (
      builtins.map ({ title, target, ... }: lib.nameValuePair title target) pagesToRender
    );
  }
  ''
    function docgen {
      md_file="$1"
      in_file="$2"
      name="$3"
      out_file="$out/$4/index.md"
      title="$5"

      if [[ -z "$in_file" ]]; then
        if [[ -z "$md_file" ]]; then
          >&2 echo "No markdown or nix file for $name"
          exit 1
        fi
      elif [[ -f "$in_file/default.nix" ]]; then
        in_file+="/default.nix"
      elif [[ ! -f "$in_file" ]]; then
        >&2 echo "File not found: $in_file"
        exit 1
      fi

      if [[ -n "$in_file" ]]; then
        nixdoc \
          --file "$in_file" \
          --locs "$locations" \
          --category "$name" \
          --description "REMOVED BY TAIL" \
          --prefix "lib" \
          --anchor-prefix "" \
        | tail --lines +2 \
        > functions.md
      fi

      default_heading="# $name"
      if [[ -n "$title" ]]; then
        default_heading+=": $title"
      fi

      print_heading=true
      if [[ -f "$md_file" ]] && [[ "$(head --lines 1 "$md_file")" == '# '* ]]; then
        >&2 echo "NOTE: markdown file for $name starts with a <h1> heading. Skipping default heading \"$default_heading\"."
        >&2 echo "      Found \"$(head --lines 1 "$md_file")\" in: $md_file"
        print_heading=false
      fi

      mkdir -p $(dirname "$out_file")
      (
        if [[ "$print_heading" = true ]]; then
          echo "$default_heading"
          echo
        fi
        if [[ -f "$md_file" ]]; then
          cat "$md_file"
          echo
        fi
        if [[ -f functions.md ]]; then
          cat functions.md
        fi
      ) > "$out_file"
    }

    mkdir -p "$out"

    ${lib.concatMapStringsSep "\n" (
      {
        libLoc,
        libFile,
        source,
        target,
        title ? "",
        ...
      }:
      lib.escapeShellArgs [
        "docgen"
        "${lib.optionalString (source != null) source}" # md_file
        "${lib.optionalString (libFile != null) libFile}" # in_file
        (lib.optionalString (libLoc != null) (lib.showAttrPath libLoc)) # name
        target # out_file
        title # title
      ]
    ) pagesToRender}
  ''
