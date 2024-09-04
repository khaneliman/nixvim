{
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) types;
in
lib.nixvim.vim-plugin.mkVimPlugin {
  name = "dracula";
  isColorscheme = true;
  defaultPackage = pkgs.vimPlugins.dracula-vim;
  globalPrefix = "dracula_";

  # TODO: added 2024-09-03 remove after 24.11
  optionsRenamedToSettings = [
    "bold"
    "italic"
    "underline"
    "undercurl"
    "fullSpecialAttrsSupport"
    "highContrastDiff"
    "inverse"
    "colorterm"
  ];

  settingsOptions = {
    bold = lib.mkOption {
      type = types.bool;
      default = true;
      description = "Include bold attributes in highlighting";
    };
    italic = lib.mkOption {
      type = types.bool;
      default = true;
      description = "Include italic attributes in highlighting";
    };
    underline = lib.mkOption {
      type = types.bool;
      default = true;
      description = "Include underline attributes in highlighting";
    };
    undercurl = lib.mkOption {
      type = types.bool;
      default = true;
      description = "Include undercurl attributes in highlighting (only if underline enabled)";
    };

    fullSpecialAttrsSupport = lib.mkOption {
      type = types.bool;
      default = false;
      description = "Explicitly declare full support for special attributes. On terminal emulators, set to 1 to allow underline/undercurl highlights without changing the foreground color";
    };

    highContrastDiff = lib.mkOption {
      type = types.bool;
      default = false;
      description = "Use high-contrast color when in diff mode";
    };

    inverse = lib.mkOption {
      type = types.bool;
      default = true;
      description = "Include inverse attributes in highlighting";
    };

    colorterm = lib.mkOption {
      type = types.bool;
      default = true;
      description = "Include background fill colors";
    };
  };

  extraConfig = cfg: {
    opts.termguicolors = lib.mkDefault true;
  };
}
