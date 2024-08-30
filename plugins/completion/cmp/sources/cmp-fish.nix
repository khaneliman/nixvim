{
  lib,
  config,
  pkgs,
  helpers,
  ...
}:
let
  cfg = config.plugins.cmp-fish;
in
{
  meta.maintainers = [ lib.maintainers.GaetanLepage ];

  options.plugins.cmp-fish = {
    fishPackage = helpers.mkPackageOption {
      name = "fish";
      default = pkgs.fish;
    };
  };

  config = lib.mkIf cfg.enable { extraPackages = [ cfg.fishPackage ]; };
}
