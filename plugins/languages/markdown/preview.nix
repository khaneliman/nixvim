{
  lib,
  helpers,
  config,
  pkgs,
  ...
}:

helpers.neovim-plugin.mkNeovimPlugin config {
  name = "preview";
  originalName = "Preview.nvim";
  defaultPackage = pkgs.vimPlugins.Preview-nvim;

  hasSettings = false;

  maintainers = [ maintainers.GaetanLepage ];
}
