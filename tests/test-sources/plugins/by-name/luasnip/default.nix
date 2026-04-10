{
  empty = {
    plugins.luasnip.enable = true;
  };

  example = {
    plugins.luasnip = {
      enable = true;

      settings = {
        history = true;
        updateevents = "TextChanged,TextChangedI";
        enable_autosnippets = true;
        ext_opts = {
          "__rawKey__require('luasnip.util.types').choiceNode".active.virt_text = [
            [
              "●"
              "GruvboxOrange"
            ]
          ];
          "__rawKey__require('luasnip.util.types').insertNode".active.virt_text = [
            [
              "●"
              "GruvboxBlue"
            ]
          ];
        };
      };
    };
  };

  friendly-snippets =
    { config, lib, ... }:
    {
      test.runNvim = false;

      plugins = {
        friendly-snippets.enable = true;
        luasnip = {
          enable = true;
          enableFriendlySnippetsIntegration = true;
        };
      };

      assertions = [
        {
          assertion = lib.hasInfix "from_vscode" config.plugins.luasnip.luaConfig.content;
          message = "Expected luasnip to load VSCode snippets.";
        }
        {
          assertion = lib.hasInfix (builtins.unsafeDiscardStringContext "${config.plugins.friendly-snippets.package}") config.plugins.luasnip.luaConfig.content;
          message = "Expected luasnip to load snippets from the friendly-snippets package.";
        }
      ];
    };

  friendly-snippets-missing-dependency = {
    test = {
      runNvim = false;
      assertions = expect: [
        (expect "count" 1)
        (expect "any" "`enableFriendlySnippetsIntegration` requires `plugins.friendly-snippets.enable`")
      ];
    };

    plugins.luasnip = {
      enable = true;
      enableFriendlySnippetsIntegration = true;
    };
  };
}
