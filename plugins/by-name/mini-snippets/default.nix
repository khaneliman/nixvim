{
  lib,
  config,
  ...
}:
lib.nixvim.plugins.mkNeovimPlugin {
  name = "mini-snippets";
  moduleName = "mini.snippets";

  maintainers = [ lib.maintainers.HeitorAugustoLN ];

  extraOptions = {
    enableFriendlySnippetsIntegration = lib.mkEnableOption "friendly-snippets integration";
  };

  settingsExample = {
    snippets = lib.nixvim.nestedLiteral (lib.literalExpression "lib.nixvim.emptyTable");

    mappings = {
      expand = "<C-j>";
      jump_next = "<C-l>";
      jump_prev = "<C-h>";
      stop = "<C-c>";
    };

    expand = {
      prepare = lib.nixvim.nestedLiteralLua "nil";
      match = lib.nixvim.nestedLiteralLua "nil";
      select = lib.nixvim.nestedLiteralLua "nil";
      insert = lib.nixvim.nestedLiteralLua "nil";
    };
  };

  extraConfig = cfg: {
    assertions = lib.nixvim.mkAssertions "plugins.mini-snippets" {
      assertion = !cfg.enableFriendlySnippetsIntegration || config.plugins.friendly-snippets.enable;
      message = ''
        `enableFriendlySnippetsIntegration` requires `plugins.friendly-snippets.enable` to be true.
      '';
    };

    plugins.mini-snippets.luaConfig.post = lib.mkIf cfg.enableFriendlySnippetsIntegration ''
      do
        local gen_loader = require('mini.snippets').gen_loader
        vim.list_extend(MiniSnippets.config.snippets, {
          gen_loader.from_file('${config.plugins.friendly-snippets.package}/snippets/global.json'),
          gen_loader.from_lang(),
        })
      end
    '';
  };
}
