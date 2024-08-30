{
  lib,
  helpers,
  config,
  pkgs,
  ...
}:
# We use `mkVimPlugin` to avoid having a `settings` option.
# Indeed, this plugin is not configurable in the common sense (no `setup` function).
helpers.vim-plugin.mkVimPlugin config {
  name = "gitignore";
  originalName = "gitignore.nvim";
  defaultPackage = pkgs.vimPlugins.gitignore-nvim;

  maintainers = [ lib.maintainers.GaetanLepage ];

  extraOptions = {
    keymap = lib.mkOption {
      type =
        with lib.types;
        nullOr (
          either str (submodule {
            options = {
              key = lib.mkOption {
                type = str;
                description = "The key to map.";
                example = "<leader>gi";
              };

              mode = helpers.keymaps.mkModeOption "n";

              options = helpers.keymaps.mapConfigOptions;
            };
          })
        );
      default = null;
      description = ''
        Keyboard shortcut for the `gitignore.generate` command.
        Can be:
        - A string: which key to bind
        - An attrs: if you want to customize the mode and/or the options of the keymap
          (`desc`, `silent`, ...)
      '';
      example = "<leader>gi";
    };
  };

  extraConfig = cfg: {
    keymaps = lib.optional (cfg.keymap != null) (
      (
        if lib.isString cfg.keymap then
          {
            mode = "n";
            key = cfg.keymap;
          }
        else
          cfg.keymap
      )
      // {
        action.__raw = "require('gitignore').generate";
      }
    );
  };
}
