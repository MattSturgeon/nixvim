{
  lib,
  config,
  pkgs,
  ...
}:
let
  fileModule =
    {
      name,
      config,
      options,
      ...
    }:
    {
      options = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = ''
            Whether this file should be generated.
            This option allows specific files to be disabled.
          '';
        };

        target = lib.mkOption {
          type = lib.types.str;
          defaultText = lib.literalMD "the attribute name";
          default = name;
          description = ''
            Name of the symlink in the markdown source.
          '';
        };

        text = lib.mkOption {
          type = with lib.types; nullOr lines;
          default = null;
          description = "Text of the file.";
        };

        source = lib.mkOption {
          type = lib.types.path;
          description = "Path of the source file.";
        };
      };

      config =
        let
          derivationName = lib.replaceStrings [ "/" ] [ "-" ] name;
        in
        {
          source = lib.mkIf (config.text != null) (
            lib.mkDerivedConfig options.text (pkgs.writeText derivationName)
          );
        };
    };

  fileType = lib.types.submodule fileModule;
in
{
  options.docs.src = lib.mkOption {
    type = lib.types.attrsOf fileType;
    description = "Source files from which to build the html website.";
    default = { };
  };

  config.docs.src =
    let
      pagesToFiles = pages: builtins.concatMap pageToFiles (builtins.attrValues pages);

      pageToFiles =
        page:
        lib.optional (page.markdown != null) {
          ${page.target} = {
            # TODO: add ".md" suffix?
            inherit (page) target;
            source = page.markdown;
          };
        }
        ++ pagesToFiles page.pages;
    in
    lib.mkMerge (pagesToFiles config.meta.pages);
}
