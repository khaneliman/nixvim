{
  lib,
  helpers,
  config,
  pkgs,
  ...
}:
{
  options.plugins.netman = {
    enable = lib.mkEnableOption "netman.nvim, a framework to access remote resources";

    package = helpers.mkPluginPackageOption "netman.nvim" pkgs.vimPlugins.netman-nvim;

    neoTreeIntegration = lib.mkEnableOption "support for netman as a neo-tree source";
  };

  config =
    let
      cfg = config.plugins.netman;
    in
    lib.mkIf cfg.enable {
      extraPlugins = [ cfg.package ];
      extraConfigLua = ''
        require("netman")
      '';

      plugins.neo-tree.extraSources = lib.mkIf cfg.neoTreeIntegration [ "netman.ui.neo-tree" ];
    };
}
