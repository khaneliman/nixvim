{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib.nixvim) mkPluginPackageOption mkSettingsOption toLuaObject;
  supportedAdapters = import ./adapters-list.nix;

  mkAdapter =
    name:
    {
      treesitter-parser,
      packageName ? "neotest-${name}",
      settingsSuffix ? settingsLua: "(${settingsLua})",
    }:
    {
      options.plugins.neotest.adapters.${name} = {
        enable = lib.mkEnableOption name;

        package = mkPluginPackageOption name pkgs.vimPlugins.${packageName};

        settings = mkSettingsOption { description = "settings for the `${name}` adapter."; };
      };

      config =
        let
          cfg = config.plugins.neotest.adapters.${name};
        in
        lib.mkIf cfg.enable {
          extraPlugins = [ cfg.package ];

          assertions = [
            {
              assertion = config.plugins.neotest.enable;
              message = "Nixvim: you have enabled `plugins.neotest.adapters.${name}` but `plugins.neotest.enable` is `false`.";
            }
          ];

          warnings = lib.optional (!config.plugins.treesitter.enable) ''
            Nixvim (plugins.neotest.adapters.${name}): This adapter requires `treesitter` to be enabled.
            You might want to set `plugins.treesitter.enable = true` and ensure that the `${lib.props.treesitter-parser}` parser is enabled.
          '';

          plugins.neotest.settings.adapters =
            let
              settingsString = lib.optionalString (cfg.settings != { }) (
                settingsSuffix (toLuaObject cfg.settings)
              );
            in
            [ "require('neotest-${name}')${settingsString}" ];
        };
    };
in
{
  imports = lib.mapAttrsToList mkAdapter supportedAdapters;
}
