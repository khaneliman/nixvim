{
  lib,
  helpers,
  config,
  options,
  pkgs,
  ...
}:
let
  settingsOptions = {
    fzf_bin = helpers.mkNullOrStr ''
      The path to the `fzf` binary to use.

      Example: `"skim"`
    '';
  };
  settingsExample = {
    winopts = {
      height = 0.4;
      width = 0.93;
      row = 0.99;
      col = 0.3;
    };
    files = {
      find_opts.__raw = "[[-type f -not -path '*.git/objects*' -not -path '*.env*']]";
      prompt = "Files❯ ";
      multiprocess = true;
      file_icons = true;
      color_icons = true;
    };
  };
in
helpers.neovim-plugin.mkNeovimPlugin config {
  name = "fzf-lua";
  defaultPackage = pkgs.vimPlugins.fzf-lua;

  extraPackages = [ pkgs.fzf ];

  maintainers = [ lib.maintainers.GaetanLepage ];

  inherit settingsOptions settingsExample;

  extraOptions = {
    fzfPackage = helpers.mkPackageOption {
      name = "fzf";
      default = pkgs.fzf;
      example = pkgs.skim;
    };

    # TODO: deprecated 2024-08-29 remove after 24.11
    iconsEnabled = lib.mkOption {
      type = lib.types.bool;
      description = "Toggle icon support. Installs nvim-web-devicons.";
      visible = false;
    };

    iconsPackage = helpers.mkPackageOption {
      name = "nvim-web-devicons";
      default = pkgs.vimPlugins.nvim-web-devicons;
    };

    profile = helpers.defaultNullOpts.mkEnumFirstDefault [
      "default"
      "fzf-native"
      "fzf-tmux"
      "fzf-vim"
      "max-perf"
      "telescope"
      "skim"
    ] "Preconfigured profile to use";

    keymaps = lib.mkOption {
      type =
        with lib.types;
        attrsOf (
          either str (submodule {
            options = {
              action = lib.mkOption {
                type = types.str;
                description = "The `fzf-lua` action to run";
                example = "git_files";
              };
              settings = helpers.mkSettingsOption {
                options = settingsOptions;
                description = "`fzf-lua` settings for this command.";
                example = settingsExample;
              };
              mode = helpers.keymaps.mkModeOption "n";
              options = helpers.keymaps.mapConfigOptions;
            };
          })
        );
      description = "Keymaps for Fzf-Lua.";
      default = { };
      example = {
        "<leader>fg" = "live_grep";
        "<C-p>" = {
          action = "git_files";
          settings = {
            previewers.cat.cmd = "${pkgs.coreutils}/bin/cat";
            winopts.height = 0.5;
          };
          options = {
            silent = true;
            desc = "Fzf-Lua Git Files";
          };
        };
      };
    };
  };

  extraConfig =
    cfg:
    let
      opt = options.plugins.fzf-lua;
    in
    {
      # TODO: deprecated 2024-08-29 remove after 24.11
      warnings = lib.mkIf opt.iconsEnabled.isDefined [
        ''
          nixvim (plugins.fzf-lua):
          The option definition `plugins.fzf-lua.iconsEnabled' in ${lib.showFiles opt.iconsEnabled.files} has been deprecated; please remove it.
          You should use `plugins.fzf-lua.iconsPackage' instead.
        ''
      ];

      extraPlugins = lib.mkIf (
        cfg.iconsPackage != null && (opt.iconsEnabled.isDefined -> cfg.iconsEnabled)
      ) [ cfg.iconsPackage ];

      extraPackages = [ cfg.fzfPackage ];

      plugins.fzf-lua.settings.__unkeyed_profile = cfg.profile;

      keymaps = lib.mapAttrsToList (
        key: mapping:
        let
          actionStr =
            if lib.isString mapping then
              "${mapping}()"
            else
              "${mapping.action}(${helpers.toLuaObject mapping.settings})";
        in
        {
          inherit key;
          mode = mapping.mode or "n";
          action.__raw = "function() require('fzf-lua').${actionStr} end";
          options = mapping.options or { };
        }
      ) cfg.keymaps;
    };
}
