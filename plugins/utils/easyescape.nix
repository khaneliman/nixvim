{
  lib,
  helpers,
  config,
  pkgs,
  ...
}:
let
  cfg = config.plugins.easyescape;
in
{
  options = {
    plugins.easyescape = {
      enable = lib.mkEnableOption "easyescape";

      package = helpers.mkPluginPackageOption "easyescape" pkgs.vimPlugins.vim-easyescape;
    };
  };
  config = lib.mkIf cfg.enable { extraPlugins = [ cfg.package ]; };
}
