{
  lib,
  helpers,
  config,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.plugins.nvim-colorizer;

  colorizer-options = {
    RGB = lib.mkOption {
      description = "#RGB hex codes";
      type = types.nullOr types.bool;
      default = null;
    };
    RRGGBB = lib.mkOption {
      description = "#RRGGBB hex codes";
      type = types.nullOr types.bool;
      default = null;
    };
    names = lib.mkOption {
      description = "\"Name\" codes like Blue or blue";
      type = types.nullOr types.bool;
      default = null;
    };
    RRGGBBAA = lib.mkOption {
      description = "#RRGGBBAA hex codes";
      type = types.nullOr types.bool;
      default = null;
    };
    AARRGGBB = lib.mkOption {
      description = "0xAARRGGBB hex codes";
      type = types.nullOr types.bool;
      default = null;
    };
    rgb_fn = lib.mkOption {
      description = "CSS rgb() and rgba() functions";
      type = types.nullOr types.bool;
      default = null;
    };
    hsl_fn = lib.mkOption {
      description = "CSS hsl() and hsla() functions";
      type = types.nullOr types.bool;
      default = null;
    };
    css = lib.mkOption {
      description = "Enable all CSS features: rgb_fn, hsl_fn, names, RGB, RRGGBB";
      type = types.nullOr types.bool;
      default = null;
    };
    css_fn = lib.mkOption {
      description = "Enable all CSS *functions*: rgb_fn, hsl_fn";
      type = types.nullOr types.bool;
      default = null;
    };
    mode = lib.mkOption {
      description = "Set the display mode";
      type = types.nullOr (
        types.enum [
          "foreground"
          "background"
          "virtualtext"
        ]
      );
      default = null;
    };
    tailwind = lib.mkOption {
      description = "Enable tailwind colors";
      type = types.nullOr (
        types.oneOf [
          types.bool
          (types.enum [
            "normal"
            "lsp"
            "both"
          ])
        ]
      );
      default = null;
    };
    sass = {
      enable = lib.mkOption {
        description = "Enable sass colors";
        type = types.nullOr types.bool;
        default = null;
      };
      parsers = lib.mkOption {
        description = "sass parsers settings";
        type = types.nullOr types.attrs;
        default = null;
      };
    };
    virtualtext = lib.mkOption {
      description = "Set the virtualtext character (only used when mode is set to 'virtualtext')";
      type = types.nullOr types.str;
      default = null;
    };
  };
in
{
  options = {
    plugins.nvim-colorizer = {
      enable = mkEnableOption "nvim-colorizer";

      package = helpers.mkPluginPackageOption "nvim-colorizer" pkgs.vimPlugins.nvim-colorizer-lua;

      fileTypes = lib.mkOption {
        description = "Enable and/or configure highlighting for certain filetypes";
        type =
          with types;
          nullOr (
            listOf (
              either str (
                types.submodule {
                  options = {
                    language = lib.mkOption {
                      type = types.str;
                      description = "The language this configuration should apply to.";
                    };
                  } // colorizer-options;
                }
              )
            )
          );
        default = null;
      };

      userDefaultOptions = lib.mkOption {
        description = "Default options";
        type = types.nullOr (types.submodule { options = colorizer-options; });
        default = null;
      };

      bufTypes = lib.mkOption {
        description = "Buftype value is fetched by vim.bo.buftype";
        type = types.nullOr (types.listOf types.str);
        default = null;
      };
    };
  };

  config = mkIf cfg.enable {
    extraPlugins = [ cfg.package ];

    extraConfigLua =
      let
        filetypes =
          if (cfg.fileTypes != null) then
            (
              let
                list = map (
                  v:
                  if builtins.isAttrs v then
                    v.language + " = " + helpers.toLuaObject (builtins.removeAttrs v [ "language" ])
                  else
                    "'${v}'"
                ) cfg.fileTypes;
              in
              "{" + (concatStringsSep "," list) + "}"
            )
          else
            "nil";
      in
      ''
        require("colorizer").setup({
          filetypes = ${filetypes},
          user_default_options = ${helpers.toLuaObject cfg.userDefaultOptions},
          buftypes = ${helpers.toLuaObject cfg.bufTypes},
        })
      '';
  };
}
