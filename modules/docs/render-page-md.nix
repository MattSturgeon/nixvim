{
  # Dependencies
  lib,
  path,
  nixos-render-docs,
  runCommand,

  # Arguments
  name,
  text ? null,
  source ? null,
  optionsJSON ? null,
  revision ? "",
}:
runCommand "page-${name}.md"
  {
    inherit
      text
      source
      optionsJSON
      revision
      ;

    nativeBuildInputs = lib.optionals (optionsJSON != null) [
      nixos-render-docs
    ];
  }
  ''
    ${lib.optionalString (optionsJSON != null)
      # bash
      ''
        nixos-render-docs -j $NIX_BUILD_CORES \
          options commonmark \
          --manpage-urls ${path + "/doc/manpage-urls.json"} \
          --revision "$revision" \
          --anchor-prefix opt- \
          --anchor-style legacy \
          $optionsJSON options.md
      ''
    }

    (
      if test -n "$text"; then
        echo "$text"
        echo
        echo
      fi
      if test -f "$source"; then
        cat "$source"
        echo
        echo
      fi
      if test -f options.md; then
        cat options.md
      fi
    ) > $out
  ''
