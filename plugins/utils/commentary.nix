{
  lib,
  helpers,
  config,
  pkgs,
  ...
}:
let
  cfg = config.plugins.commentary;
in
{
  # TODO Add support for additional filetypes. This requires autocommands!

  options = {
    plugins.commentary = {
      enable = lib.mkEnableOption "commentary";

      package = helpers.mkPluginPackageOption "commentary" pkgs.vimPlugins.vim-commentary;
    };
  };

  config = lib.mkIf cfg.enable { extraPlugins = [ cfg.package ]; };
}
