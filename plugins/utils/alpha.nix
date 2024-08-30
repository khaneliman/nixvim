{
  lib,
  helpers,
  config,
  options,
  pkgs,
  ...
}:
let
  cfg = config.plugins.alpha;

  sectionType = lib.types.submodule {
    freeformType = with lib.types; attrsOf anything;
    options = {
      type = lib.mkOption {
        type = lib.types.enum [
          "button"
          "group"
          "padding"
          "text"
          "terminal"
        ];
        description = "Type of section";
      };

      val = helpers.mkNullOrOption (
        with helpers.nixvimTypes;
        nullOr (oneOf [
          # "button", "text"
          str
          # "padding"
          int
          (listOf (
            either
              # "text" (list of strings)
              str
              # "group"
              (attrsOf anything)
          ))
        ])
      ) "Value for section";

      opts = lib.mkOption {
        type = with lib.types; attrsOf anything;
        default = { };
        description = "Additional options for the section";
      };
    };
  };
in
{
  options = {
    plugins.alpha = {
      enable = lib.mkEnableOption "alpha-nvim";

      package = helpers.mkPluginPackageOption "alpha-nvim" pkgs.vimPlugins.alpha-nvim;

      # TODO: deprecated 2024-08-29 remove after 24.11
      iconsEnabled = lib.mkOption {
        type = lib.types.bool;
        description = "Toggle icon support. Installs nvim-web-devicons.";
        visible = false;
      };

      iconsPackage = helpers.mkPackageOption {
        name = "nvim-web-devicons";
        default = pkgs.vimPlugins.nvim-web-devicons;
      };

      theme = lib.mkOption {
        type = with helpers.nixvimTypes; nullOr (maybeRaw str);
        apply = v: if lib.isString v then helpers.mkRaw "require'alpha.themes.${v}'.config" else v;
        default = null;
        example = "dashboard";
        description = "You can directly use a pre-defined theme.";
      };

      layout = lib.mkOption {
        type = lib.types.listOf sectionType;
        default = [ ];
        description = "List of sections to layout for the dashboard";
        example = [
          {
            type = "padding";
            val = 2;
          }
          {
            type = "text";
            val = [
              "███╗   ██╗██╗██╗  ██╗██╗   ██╗██╗███╗   ███╗"
              "████╗  ██║██║╚██╗██╔╝██║   ██║██║████╗ ████║"
              "██╔██╗ ██║██║ ╚███╔╝ ██║   ██║██║██╔████╔██║"
              "██║╚██╗██║██║ ██╔██╗ ╚██╗ ██╔╝██║██║╚██╔╝██║"
              "██║ ╚████║██║██╔╝ ██╗ ╚████╔╝ ██║██║ ╚═╝ ██║"
              "╚═╝  ╚═══╝╚═╝╚═╝  ╚═╝  ╚═══╝  ╚═╝╚═╝     ╚═╝"
            ];
            opts = {
              position = "center";
              hl = "Type";
            };
          }
          {
            type = "padding";
            val = 2;
          }
          {
            type = "group";
            val = [
              {
                type = "button";
                val = "  New file";
                on_press.__raw = "function() vim.cmd[[ene]] end";
                opts.shortcut = "n";
              }
              {
                type = "button";
                val = " Quit Neovim";
                on_press.__raw = "function() vim.cmd[[qa]] end";
                opts.shortcut = "q";
              }
            ];
          }
          {
            type = "padding";
            val = 2;
          }
          {
            type = "text";
            val = "Inspiring quote here.";
            opts = {
              position = "center";
              hl = "Keyword";
            };
          }
        ];
      };

      opts = helpers.mkNullOrOption (with lib.types; attrsOf anything) ''
        Optional global options.
      '';
    };
  };

  config =
    let
      layoutDefined = cfg.layout != [ ];
      themeDefined = cfg.theme != null;

      opt = options.plugins.alpha;
    in
    lib.mkIf cfg.enable {
      # TODO: deprecated 2024-08-29 remove after 24.11
      warnings = lib.mkIf opt.iconsEnabled.isDefined [
        ''
          nixvim (plugins.alpha):
          The option definition `plugins.alpha.iconsEnabled' in ${lib.showFiles opt.iconsEnabled.files} has been deprecated; please remove it.
          You should use `plugins.alpha.iconsPackage' instead.
        ''
      ];

      extraPlugins =
        [ cfg.package ]
        ++ lib.optional (
          cfg.iconsPackage != null && (opt.iconsEnabled.isDefined -> cfg.iconsEnabled)
        ) cfg.iconsPackage;

      assertions = [
        {
          assertion = themeDefined || layoutDefined;
          message = ''
            Nixvim (plugins.alpha): You have to either set a `theme` or define some sections in `layout`.
          '';
        }
        {
          assertion = !(themeDefined && layoutDefined);
          message = ''
            Nixvim (plugins.alpha): You can't define both a `theme` and custom options.
            Set `plugins.alpha.theme = null` if you want to configure alpha manually using the `layout` option.
          '';
        }
      ];

      extraConfigLua =
        let
          setupOptions =
            if themeDefined then
              cfg.theme
            else
              (with cfg; {
                inherit layout opts;
              });
        in
        ''
          require('alpha').setup(${helpers.toLuaObject setupOptions})
        '';
    };
}
