{
  lib,
  helpers,
  config,
  pkgs,
  ...
}:
let
  cfg = config.plugins.mini;
in
{
  options.plugins.mini = {
    enable = lib.mkEnableOption "mini.nvim";

    package = helpers.mkPluginPackageOption "mini.nvim" pkgs.vimPlugins.mini-nvim;

    modules = lib.mkOption {
      type = with lib.types; attrsOf attrs;
      default = { };
      description = ''
        Enable and configure the mini modules.
        The keys are the names of the modules (without the `mini.` prefix).
        The value is an attrs of configuration options for the module.
        Leave the attrs empty to use the module's default configuration.
      '';
      example = {
        ai = {
          n_lines = 50;
          search_method = "cover_or_next";
        };
        surround = { };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    extraPlugins = [ cfg.package ];

    extraConfigLua = lib.concatLines (
      lib.mapAttrsToList (
        name: config: "require('mini.${name}').setup(${helpers.toLuaObject config})"
      ) cfg.modules
    );
  };
}
