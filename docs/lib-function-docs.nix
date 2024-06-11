# Generates the documentation for library functions via nixdoc.
{
  # TODO decide which args should be set here vs in lib-function-locations.nix
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
  locationsJSON ? import ./lib-function-locations.nix {
    inherit
      pkgs
      lib
      libName
      targetLib
      libsets
      pathPrefix
      urlPrefix
      revision
      ;
  },
}:

pkgs.stdenv.mkDerivation {
  name = "nixvim-lib-docs";
  src = ../lib;

  buildInputs = [ pkgs.nixdoc ];
  installPhase = ''
    function docgen {
      name=$1
      basename=$2
      description=$3
      nixFile="../lib/$basename.nix"
      if [ ! -e "$nixFile" ]; then
        nixFile="../lib/$basename/default.nix"
      fi
      echo "Opening $(realpath $nixFile) with ${locationsJSON}"
      nixdoc \
        --prefix "helpers" \
        --category "$name" \
        --description "${libName}.$name: $description" \
        --locs ${locationsJSON} \
        --file "$nixFile" \
        > "$out/$name.md"
      echo "$out/$name.md" >> "$out/index.md"
    }

    mkdir -p "$out"

    cat > "$out/index.md" << 'EOF'
    ```{=include=} sections auto-id-prefix=auto-generated
    EOF

    ${lib.strings.concatStringsSep "\n" (
      lib.attrsets.mapAttrsToList (
        name: v:
        let
          basename = v.basename or name;
          description = if builtins.isString v then v else v.description or "";
        in
        "docgen ${name} ${basename} ${lib.escapeShellArg description}"
      ) libsets
    )}

    echo '```' >> "$out/index.md"
  '';
}
