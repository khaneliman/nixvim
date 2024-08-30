{
  lib,
  helpers,
  config,
  pkgs,
  ...
}:
let
  cfg = config.plugins.helm;
in
{
  meta.maintainers = [ lib.maintainers.GaetanLepage ];

  options.plugins.helm = {
    enable = lib.mkEnableOption "vim-helm";

    package = helpers.mkPluginPackageOption "vim-helm" pkgs.vimPlugins.vim-helm;
  };

  config = lib.mkIf cfg.enable { extraPlugins = [ cfg.package ]; };
}
