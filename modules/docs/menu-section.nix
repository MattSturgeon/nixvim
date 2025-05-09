{ lib, name, ... }:
{
  options = {
    title = lib.mkOption {
      type = lib.types.str;
      default = name;
      defaultText = lib.literalMD "the attribute name";
      description = ''
        The section's heading/title.
      '';
    };
    order = lib.mkOption {
      type = lib.types.ints.unsigned;
      default = 1000;
      description = ''
        The relative position in the menu for this section.
      '';
    };
  };
}
