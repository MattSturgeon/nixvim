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
      baseName=$2
      description=$3
      pwd
      ls -a
      ls -a ../lib
      # TODO: wrap lib.$name in <literal>, make nixdoc not escape it
      if [[ -e "../lib/$baseName.nix" ]]; then
        echo "Found .nix file"
        nixdoc -c "$name" -d "lib.$name: $description" -l ${locationsJSON} -f "$baseName.nix" > "$out/$name.md"
      else
        echo "Using default.nix file"
        nixdoc -c "$name" -d "lib.$name: $description" -l ${locationsJSON} -f "$baseName/default.nix" > "$out/$name.md"
      fi
      echo "Writing $out/$name.md to $out/index.md"
      echo "$out/$name.md" >> "$out/index.md"
    }

    mkdir -p "$out"

    cat > "$out/index.md" << 'EOF'
    ```{=include=} sections auto-id-prefix=auto-generated
    EOF

    ${lib.strings.concatStrings (
      lib.attrsets.mapAttrsToList (
        # FIXME: the docgen function (above) allows name to be different to file's basename,
        # but we use a simple {name:description} attrset for `libsets`...
        name: description: ''
          echo "About to run docgen for ${name}"
          docgen ${name} ${name} ${lib.escapeShellArg description}
        '') libsets
    )}

    echo '```' >> "$out/index.md"
  '';
}
