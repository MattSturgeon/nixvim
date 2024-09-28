{
  lib,
  self,
}:
let
  inherit (lib) types;
in
rec {
  autoGroupOption = types.submodule {
    options = {
      clear = lib.mkOption {
        type = types.bool;
        description = "Clear existing commands if the group already exists.";
        default = true;
      };
    };
  };

  autoCmdOptions = {
    event = self.mkNullOrOption (with types; either str (listOf str)) ''
      The event or events to register this autocommand.
    '';

    group = self.mkNullOrOption (with types; either str int) ''
      The autocommand group name or id to match against.
    '';

    pattern = self.mkNullOrOption (with types; either str (listOf str)) ''
      Pattern or patterns to match literally against.
    '';

    buffer = self.mkNullOrOption types.int ''
      Buffer number for buffer local autocommands |autocmd-buflocal|.
      Cannot be used with `pattern`.
    '';

    # Introduced early October 2023.
    # TODO remove in early December 2023.
    description = self.mkNullOrOption types.str ''
      DEPRECATED, please use `desc`.
    '';

    desc = self.mkNullOrOption types.str ''
      A textual description of this autocommand.
    '';

    callback = self.mkNullOrOption (with types; either str self.types.rawLua) ''
      A function or a string.
      - if a string, the name of a Vimscript function to call when this autocommand is triggered.
      - Otherwise, a Lua function which is called when this autocommand is triggered.
        Cannot be used with `command`.
        Lua callbacks can return true to delete the autocommand; in addition, they accept a single
        table argument with the following keys:
        - id: (number) the autocommand id
        - event: (string) the name of the event that triggered the autocommand |autocmd-events|
        - group: (number|nil) the autocommand group id, if it exists
        - match: (string) the expanded value of |<amatch>|
        - buf: (number) the expanded value of |<abuf>|
        - file: (string) the expanded value of |<afile>|
        - data: (any) arbitrary data passed to |nvim_exec_autocmds()|

      Example using callback:
      autoCmd = [
        {
          event = [ "BufEnter" "BufWinEnter" ];
          pattern = [ "*.c" "*.h" ];
          callback = { __raw = "function() print('This buffer enters') end"; };
        }
    '';

    command = self.defaultNullOpts.mkStr "" ''
      Vim command to execute on event. Cannot be used with `callback`.
    '';

    once = self.defaultNullOpts.mkBool false "Run the autocommand only once.";

    nested = self.defaultNullOpts.mkBool false "Run nested autocommands.";
  };

  autoCmdOption = types.submodule { options = autoCmdOptions; };
}
