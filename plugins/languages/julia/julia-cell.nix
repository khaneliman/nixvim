{
  lib,
  helpers,
  config,
  pkgs,
  ...
}:
let
  # The keys are the option name in nixvim (under plugins.julia-cell.keymaps)
  # cmd: Such that the mapping action is ':JuliaCell${cmd}<CR>'
  # desc: The description of the option.
  mappings = {
    executeCell = {
      cmd = "ExecuteCell";
      desc = "executing the current code cell";
    };
    executeCellJump = {
      cmd = "ExecuteCellJump";
      desc = "executing the current code cell and jumping to the next cell";
    };
    run = {
      cmd = "Run";
      desc = "running the entire file";
    };
    clear = {
      cmd = "Clear";
      desc = "clearing the REPL";
    };
    prevCell = {
      cmd = "PrevCell";
      desc = "jumping to the previous cell header";
    };
    nextCell = {
      cmd = "NextCell";
      desc = "jumping to the next cell header";
    };
  };
in
helpers.vim-plugin.mkVimPlugin config {
  name = "julia-cell";
  originalName = "vim-julia-cell";
  defaultPackage = pkgs.vimPlugins.vim-julia-cell;
  globalPrefix = "julia_cell_";

  maintainers = [ lib.maintainers.GaetanLepage ];

  # TODO introduced 2024-02-19: remove 2024-04-19
  deprecateExtraConfig = true;
  optionsRenamedToSettings = [
    "delimitCellsBy"
    "tag"
  ];

  settingsOptions = {
    delimit_cells_by =
      helpers.defaultNullOpts.mkEnumFirstDefault
        [
          "marks"
          "tags"
        ]
        ''
          Specifies if cells are delimited by 'marks' or 'tags'.
        '';

    tag = helpers.defaultNullOpts.mkStr "##" "Specifies the tag format.";
  };

  extraOptions = {
    keymaps =
      {
        silent = lib.mkOption {
          type = lib.types.bool;
          description = "Whether julia-cell keymaps should be silent";
          default = false;
        };
      }
      // (lib.mapAttrs (
        name: value: helpers.mkNullOrOption lib.types.str "Keymap for ${value.desc}."
      ) mappings);
  };

  extraConfig = cfg: {
    keymaps = lib.flatten (
      lib.mapAttrsToList (
        name: value:
        let
          key = cfg.keymaps.${name};
        in
        lib.optional (key != null) {
          mode = "n";
          inherit key;
          action = ":JuliaCell${value.cmd}<CR>";
          options.silent = cfg.keymaps.silent;
        }
      ) mappings
    );
  };
}
