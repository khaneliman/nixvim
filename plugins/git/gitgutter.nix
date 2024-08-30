{
  lib,
  helpers,
  config,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf types;

  cfg = config.plugins.gitgutter;
in
{
  options = {
    plugins.gitgutter = {
      enable = lib.mkEnableOption "gitgutter";

      package = helpers.mkPluginPackageOption "gitgutter" pkgs.vimPlugins.gitgutter;

      gitPackage = helpers.mkPackageOption {
        name = "git";
        default = pkgs.git;
      };

      recommendedSettings = lib.mkOption {
        type = types.bool;
        default = true;
        description = "Use recommended settings";
      };

      maxSigns = lib.mkOption {
        type = types.nullOr types.int;
        default = null;
        description = "Maximum number of signs to show on the screen. Unlimited by default.";
      };

      showMessageOnHunkJumping = lib.mkOption {
        type = types.bool;
        default = true;
        description = "Show a message when jumping between hunks";
      };

      defaultMaps = lib.mkOption {
        type = types.bool;
        default = true;
        description = "Let gitgutter set default mappings";
      };

      allowClobberSigns = lib.mkOption {
        type = types.bool;
        default = false;
        description = "Don't preserve other signs on the sign column";
      };

      signPriority = lib.mkOption {
        type = types.nullOr types.int;
        default = null;
        description = "GitGutter's sign priority on the sign column";
      };

      matchBackgrounds = lib.mkOption {
        type = types.bool;
        default = false;
        description = "Make the background colors match the sign column";
      };

      signs = lib.mkOption {
        type =
          let
            signOption =
              desc:
              lib.mkOption {
                type = types.nullOr types.str;
                default = null;
                description = "Sign for ${desc}";
              };
          in
          types.submodule {
            options = {
              added = signOption "added lines";
              modified = signOption "modified lines";
              removed = signOption "removed lines";
              modifiedAbove = signOption "modified line above";
              removedFirstLine = signOption "a removed first line";
              removedAboveAndBelow = signOption "lines removed above and  below";
              modifiedRemoved = signOption "modified and removed lines";
            };
          };
        default = { };
        description = "Custom signs for the sign column";
      };

      diffRelativeToWorkingTree = lib.mkOption {
        type = types.bool;
        default = false;
        description = "Make diffs relative to the working tree instead of the index";
      };

      extraGitArgs = lib.mkOption {
        type = types.str;
        default = "";
        description = "Extra arguments to pass to git";
      };

      extraDiffArgs = lib.mkOption {
        type = types.str;
        default = "";
        description = "Extra arguments to pass to git diff";
      };

      grep = lib.mkOption {
        type = types.nullOr (
          types.oneOf [
            (types.submodule {
              options = {
                command = lib.mkOption {
                  type = types.str;
                  description = "The command to use as a grep alternative";
                };

                package = lib.mkOption {
                  type = types.package;
                  description = "The package of the grep alternative to use";
                };
              };
            })
            types.str
          ]
        );
        default = null;
        description = "A non-standard grep to use instead of the default";
      };

      enableByDefault = lib.mkOption {
        type = types.bool;
        default = true;
        description = "Enable gitgutter by default";
      };

      signsByDefault = lib.mkOption {
        type = types.bool;
        default = true;
        description = "Show signs by default";
      };

      highlightLines = lib.mkOption {
        type = types.bool;
        default = true;
        description = "Highlight lines by default";
      };

      highlightLineNumbers = lib.mkOption {
        type = types.bool;
        default = true;
        description = "Highlight line numbers by default";
      };

      runAsync = lib.mkOption {
        type = types.bool;
        default = true;
        description = "Disable this to run git diff syncrhonously instead of asynchronously";
      };

      previewWinFloating = lib.mkOption {
        type = types.bool;
        default = false;
        description = "Preview hunks on floating windows";
      };

      useLocationList = lib.mkOption {
        type = types.bool;
        default = false;
        description = "Load chunks into windows's location list instead of the quickfix list";
      };

      terminalReportFocus = lib.mkOption {
        type = types.bool;
        default = true;
        description = "Let the terminal report its focus status";
      };
    };
  };

  config =
    let
      grepPackage = if builtins.isAttrs cfg.grep then [ cfg.grep.package ] else [ ];
      grepCommand = if builtins.isAttrs cfg.grep then cfg.grep.command else cfg.grep;
    in
    mkIf cfg.enable {
      extraPlugins = [ cfg.package ];

      opts = mkIf cfg.recommendedSettings {
        updatetime = 100;
        foldtext = "gitgutter#fold#foldtext";
      };

      extraPackages = [ cfg.gitPackage ] ++ [ grepPackage ];

      globals = {
        gitgutter_max_signs = mkIf (cfg.maxSigns != null) cfg.maxSigns;
        gitgutter_show_msg_on_hunk_jumping = mkIf (!cfg.showMessageOnHunkJumping) 0;
        gitgutter_map_keys = mkIf (!cfg.defaultMaps) 0;
        gitgutter_sign_allow_clobber = mkIf cfg.allowClobberSigns 1;
        gitgutter_sign_priority = mkIf (cfg.signPriority != null) cfg.signPriority;
        gitgutter_set_sign_backgrounds = mkIf cfg.matchBackgrounds 1;

        gitgutter_sign_added = mkIf (cfg.signs.added != null) cfg.signs.added;
        gitgutter_sign_modified = mkIf (cfg.signs.modified != null) cfg.signs.modified;
        gitgutter_sign_removed = mkIf (cfg.signs.removed != null) cfg.signs.removed;
        gitgutter_sign_removed_first_line = mkIf (
          cfg.signs.removedFirstLine != null
        ) cfg.signs.removedFirstLine;
        gitgutter_sign_removed_above_and_bellow = mkIf (
          cfg.signs.removedAboveAndBelow != null
        ) cfg.signs.removedAboveAndBelow;
        gitgutter_sign_modified_above = mkIf (cfg.signs.modifiedAbove != null) cfg.signs.modifiedAbove;

        gitgutter_diff_relative_to = mkIf cfg.diffRelativeToWorkingTree "working_tree";
        gitgutter_git_args = mkIf (cfg.extraGitArgs != "") cfg.extraGitArgs;
        gitgutter_diff_args = mkIf (cfg.extraDiffArgs != "") cfg.extraDiffArgs;

        gitgutter_grep = mkIf (grepCommand != null) grepCommand;

        gitgutter_enabled = mkIf (!cfg.enableByDefault) 0;
        gitgutter_signs = mkIf (!cfg.signsByDefault) 0;

        gitgutter_highlight_lines = mkIf (!cfg.highlightLines) 0;
        gitgutter_highlight_linenrs = mkIf (!cfg.highlightLineNumbers) 0;
        gitgutter_async = mkIf (!cfg.runAsync) 0;
        gitgutter_preview_win_floating = mkIf cfg.previewWinFloating 1;
        gitgutter_use_location_list = mkIf cfg.useLocationList 1;

        gitgutter_terminal_report_focus = mkIf (!cfg.terminalReportFocus) 0;
      };
    };
}
