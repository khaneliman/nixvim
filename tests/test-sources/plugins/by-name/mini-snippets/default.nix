{ lib }:
{
  empty = {
    plugins.mini-snippets.enable = true;
  };

  defaults = {
    plugins.mini-snippets = {
      enable = true;
      settings = {
        snippets = lib.nixvim.emptyTable;

        mappings = {
          expand = "<C-j>";
          jump_next = "<C-l>";
          jump_prev = "<C-h>";
          stop = "<C-c>";
        };

        expand = {
          prepare = lib.nixvim.mkRaw "nil";
          match = lib.nixvim.mkRaw "nil";
          select = lib.nixvim.mkRaw "nil";
          insert = lib.nixvim.mkRaw "nil";
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
        mini-snippets = {
          enable = true;
          enableFriendlySnippetsIntegration = true;
        };
      };

      assertions = [
        {
          assertion = lib.hasInfix "gen_loader.from_file" config.plugins.mini-snippets.luaConfig.content;
          message = "Expected mini-snippets to load global friendly-snippets.";
        }
        {
          assertion = lib.hasInfix "gen_loader.from_lang" config.plugins.mini-snippets.luaConfig.content;
          message = "Expected mini-snippets to load language friendly-snippets.";
        }
        {
          assertion = lib.hasInfix (builtins.unsafeDiscardStringContext "${config.plugins.friendly-snippets.package}") config.plugins.mini-snippets.luaConfig.content;
          message = "Expected mini-snippets to reference the friendly-snippets package.";
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

    plugins.mini-snippets = {
      enable = true;
      enableFriendlySnippetsIntegration = true;
    };
  };
}
