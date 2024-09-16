{
  perSystem =
    { pkgs, ... }:
    {
      apps.plugin-info.program =
        pkgs.writers.writePython3Bin "test_python3"
          {
            libraries = with pkgs.python3Packages; [ pyyaml ];
            flakeIgnore = [
              "E501" # Line length
            ];
          }
          ''
            import json
            import subprocess


            def get_plugins(flake: str) -> list[str]:
                expr = 'x: with builtins; listToAttrs (map (name: { inherit name; value = attrNames x.''${name}; }) [ "plugins" "colorschemes" ])'
                cmd = ['nix', 'eval', f"{flake}#nixvimConfiguration.options", '--apply', expr, '--json']
                out = subprocess.check_output(cmd)
                # Parse as json, converting the lists to sets
                return {k: set(v) for k, v in json.loads(out).items()}


            # FIXME: get `old` and `compact` from argparse
            old = 'github:nix-community/nixvim/336ba155ffcb20902b93873ad84527a833f57dc8'
            compact = True

            plugins = {'old': get_plugins(old), 'new': get_plugins('.')}

            # TODO: also guess at "renamed" plugins heuristically
            plugin_diff = {
                'added': {ns: plugins['new'][ns] - plugins['old'][ns] for ns in ['plugins', 'colorschemes']},
                'removed': {ns: plugins['old'][ns] - plugins['new'][ns] for ns in ['plugins', 'colorschemes']}
            }

            # Flatten the above dict into a list of entries; each with a 'name', 'namespace', & 'action' key
            # TODO: add additional metadata to each entry, such as the `originalName`, `pkg.meta.description`, etc
            plugin_entries = [
                {'name': name, 'namespace': namespace, 'action': action}
                for action, namespaces in plugin_diff.items()
                for namespace, plugins in namespaces.items()
                for name in plugins
            ]

            # Print json for use in CI matrix
            print(json.dumps(
                plugin_entries,
                separators=((',', ':') if compact else None),
                indent=(None if compact else 4),
                sort_keys=(not compact)
            ))
          '';
    };
}