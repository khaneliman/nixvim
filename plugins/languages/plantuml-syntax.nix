{
  lib,
  helpers,
  config,
  pkgs,
  ...
}:
 
{
  options.plugins.plantuml-syntax = {
    enable = mkEnableOption "plantuml syntax support";

    package = helpers.mkPluginPackageOption "plantuml-syntax" pkgs.vimPlugins.plantuml-syntax;

    setMakeprg = lib.mkOption {
      type = types.bool;
      default = true;
      description = "Set the makeprg to 'plantuml'";
    };
    executableScript = lib.mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Set the script to be called with makeprg, default to 'plantuml' in PATH";
    };
  };

  config =
    let
      cfg = config.plugins.plantuml-syntax;
    in
    mkIf cfg.enable {
      extraPlugins = [ cfg.package ];

      globals = {
        plantuml_set_makeprg = cfg.setMakeprg;
        plantuml_executable_script = cfg.executableScript;
      };
    };
}
