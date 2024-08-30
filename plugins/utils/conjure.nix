{
  lib,
  helpers,
  config,
  pkgs,
  ...
}:
let
  cfg = config.plugins.conjure;
in
{
  options.plugins.conjure = {
    enable = lib.mkEnableOption "Conjure";

    package = helpers.mkPluginPackageOption "conjure" pkgs.vimPlugins.conjure;
  };

  config = lib.mkIf cfg.enable { extraPlugins = [ cfg.package ]; };
}
