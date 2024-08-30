{
  lib,
  helpers,
  config,
  pkgs,
  ...
}:
 
helpers.vim-plugin.mkVimPlugin config {
  name = "wakatime";
  originalName = "vim-wakatime";
  defaultPackage = pkgs.vimPlugins.vim-wakatime;

  maintainers = [ maintainers.GaetanLepage ];
}
