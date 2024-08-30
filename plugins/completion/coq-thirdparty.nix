{
  lib,
  helpers,
  config,
  pkgs,
  ...
}:
let
  inherit (lib) types;
  cfg = config.plugins.coq-thirdparty;
in
{
  options.plugins.coq-thirdparty = {
    enable = lib.mkEnableOption "coq-thirdparty";

    package = helpers.mkPluginPackageOption "coq-thirdparty" pkgs.vimPlugins.coq-thirdparty;

    sources = lib.mkOption {
      type = types.listOf (
        types.submodule {
          freeformType = types.attrs;

          options = {
            src = lib.mkOption {
              type = types.str;
              description = "The name of the source";
            };

            short_name = lib.mkOption {
              type = types.nullOr types.str;
              description = ''
                A short name for the source.
                If not specified, it is uppercase `src`.
              '';
              example = "nLUA";
              default = null;
            };
          };
        }
      );
      description = ''
        List of sources.
        Each source is a free-form type, so additional settings like `accept_key` may be specified even if they are not declared by nixvim.
      '';
      default = [ ];
      example = [
        {
          src = "nvimlua";
          short_name = "nLUA";
        }
        {
          src = "vimtex";
          short_name = "vTEX";
        }
        {
          src = "copilot";
          short_name = "COP";
          accept_key = "<c-f>";
        }
        { src = "demo"; }
      ];
    };
  };

  config = lib.mkIf cfg.enable {
    extraPlugins = [ cfg.package ];

    extraConfigLua = ''
      require('coq_3p')(${helpers.toLuaObject cfg.sources})
    '';
  };
}
