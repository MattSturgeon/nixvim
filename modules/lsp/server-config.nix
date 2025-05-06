{ lib, ... }:
{
  options = {
    # Internal option for representing the entire clientconfig

    # Options relating to |vim.lsp.ClientConfig|
    # TODO: add a CI test to ensure we have an option for everything listed in `:h vim.lsp.ClientConfig`
    # Maybe these can even be generated options?
    cmd = lib.mkOption {
      description = ''
        (`string[]|fun(dispatchers: vim.lsp.rpc.Dispatchers): vim.lsp.rpc.PublicClient`)
                             command string[] that launches the language
                             server (treated as in |jobstart()|, must be
                             absolute or on `$PATH`, shell constructs like
                             "~" are not expanded), or function that creates
                             an RPC client. Function receives a
                             `dispatchers` table and returns a table with
                             member functions `request`, `notify`,
                             `is_closing` and `terminate`. See
                             |vim.lsp.rpc.request()|,
                             |vim.lsp.rpc.notify()|. For TCP there is a
                             builtin RPC client factory:
                             |vim.lsp.rpc.connect()|
      '';
    };

    cmd_cwd = lib.mkOption {
      description = ''
        (`string`, default: cwd) Directory to launch
                             the `cmd` process. Not related to `root_dir`.
      '';
    };

    cmd_env = lib.mkOption {
      description = ''
        (`table`) Environment flags to pass to the LSP
                             on spawn. Must be specified using a table.
                             Non-string values are coerced to string.
                             Example: >lua
                                 { PORT = 8080; HOST = "0.0.0.0"; }
      '';
    };

    detached = lib.mkOption {
      description = ''
        (`boolean`, default: true) Daemonize the server
                             process so that it runs in a separate process
                             group from Nvim. Nvim will shutdown the process
                             on exit, but if Nvim fails to exit cleanly this
                             could leave behind orphaned server processes.
      '';
    };

    workspace_folders = lib.mkOption {
      description = ''
        (`lsp.WorkspaceFolder[]`) List of workspace
                             folders passed to the language server. For
                             backwards compatibility rootUri and rootPath
                             will be derived from the first workspace folder
                             in this list. See `workspaceFolders` in the LSP
                             spec.
      '';
    };

    workspace_required = lib.mkOption {
      description = ''
        (`boolean`) (default false) Server requires a
                             workspace (no "single file" support).
      '';
    };

    capabilities = lib.mkOption {
      description = ''
        (`lsp.ClientCapabilities`) Map overriding the
                             default capabilities defined by
                             |vim.lsp.protocol.make_client_capabilities()|,
                             passed to the language server on
                             initialization. Hint: use
                             make_client_capabilities() and modify its
                             result.
                             • Note: To send an empty dictionary use
                               |vim.empty_dict()|, else it will be encoded
                               as an array.
      '';
    };

    handlers = lib.mkOption {
      description = ''
        (`table<string,function>`) Map of language
                             server method names to |lsp-handler|
      '';
    };

    settings = lib.mkOption {
      description = ''
        (`lsp.LSPObject`) Map with language server
                             specific settings. See the {settings} in
                             |vim.lsp.Client|.
      '';
    };

    commands = lib.mkOption {
      description = ''
        (`table<string,fun(command: lsp.Command, ctx: table)>`)
                             Table that maps string of clientside commands
                             to user-defined functions. Commands passed to
                             `start()` take precedence over the global
                             command registry. Each key must be a unique
                             command name, and the value is a function which
                             is called if any LSP action (code action, code
                             lenses, ...) triggers the command.
      '';
    };

    init_options = lib.mkOption {
      description = ''
        (`lsp.LSPObject`) Values to pass in the
                             initialization request as
                             `initializationOptions`. See `initialize` in
                             the LSP spec.
      '';
    };

    name = lib.mkOption {
      description = ''
        (`string`, default: client-id) Name in log
                             messages.
      '';
    };

    get_language_id = lib.mkOption {
      description = ''
        (`fun(bufnr: integer, filetype: string): string`)
                             Language ID as string. Defaults to the buffer
                             filetype.
      '';
    };

    offset_encoding = lib.mkOption {
      description = ''
        (`'utf-8'|'utf-16'|'utf-32'`) Called "position
                             encoding" in LSP spec, the encoding that the
                             LSP server expects. Client does not verify this
                             is correct.
      '';
    };

    on_error = lib.mkOption {
      description = ''
        (`fun(code: integer, err: string)`) Callback
                             invoked when the client operation throws an
                             error. `code` is a number describing the error.
                             Other arguments may be passed depending on the
                             error kind. See `vim.lsp.rpc.client_errors` for
                             possible errors. Use
                             `vim.lsp.rpc.client_errors[code]` to get
                             human-friendly name.
      '';
    };

    before_init = lib.mkOption {
      description = ''
        (`fun(params: lsp.InitializeParams, config: vim.lsp.ClientConfig)`)
                             Callback invoked before the LSP "initialize"
                             phase, where `params` contains the parameters
                             being sent to the server and `config` is the
                             config that was passed to |vim.lsp.start()|.
                             You can use this to modify parameters before
                             they are sent.
      '';
    };

    on_init = lib.mkOption {
      description = ''
        (`elem_or_list<fun(client: vim.lsp.Client, init_result: lsp.InitializeResult)>`)
                             Callback invoked after LSP "initialize", where
                             `result` is a table of `capabilities` and
                             anything else the server may send. For example,
                             clangd sends `init_result.offsetEncoding` if
                             `capabilities.offsetEncoding` was sent to it.
                             You can only modify the
                             `client.offset_encoding` here before any
                             notifications are sent.
      '';
    };

    on_exit = lib.mkOption {
      description = ''
        (`elem_or_list<fun(code: integer, signal: integer, client_id: integer)>`)
                             Callback invoked on client exit.
                             • code: exit code of the process
                             • signal: number describing the signal used to
                               terminate (if any)
                             • client_id: client handle
      '';
    };

    on_attach = lib.mkOption {
      description = ''
        (`elem_or_list<fun(client: vim.lsp.Client, bufnr: integer)>`)
                             Callback invoked when client attaches to a
                             buffer.
      '';
    };

    trace = lib.mkOption {
      description = ''
        (`'off'|'messages'|'verbose'`, default: "off")
                             Passed directly to the language server in the
                             initialize request. Invalid/empty values will
      '';
    };

    flags = lib.mkOption {
      description = ''
        (`table`) A table with flags for the client.
                             The current (experimental) flags are:
                             • {allow_incremental_sync}? (`boolean`,
                               default: `true`) Allow using incremental sync
                               for buffer edits
                             • {debounce_text_changes} (`integer`, default:
                               `150`) Debounce `didChange` notifications to
                               the server by the given number in
                               milliseconds. No debounce occurs if `nil`.
                             • {exit_timeout} (`integer|false`, default:
                               `false`) Milliseconds to wait for server to
                               exit cleanly after sending the "shutdown"
                               request before sending kill -15. If set to
                               false, nvim exits immediately after sending
                               the "shutdown" request to the server.
      '';
    };

    root_dir = lib.mkOption {
      description = ''
        (`string`) Directory where the LSP server will
                             base its workspaceFolders, rootUri, and
                             rootPath on initialization.
      '';
    };
  };

}
