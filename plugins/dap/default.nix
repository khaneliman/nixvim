{
  lib,
  helpers,
  config,
  pkgs,
  ...
}:
let
  cfg = config.plugins.dap;
  dapHelpers = import ./dapHelpers.nix { inherit lib helpers; };
in
{
  imports = [
    ./dap-go.nix
    ./dap-python.nix
    ./dap-ui.nix
    ./dap-virtual-text.nix
  ];

  options.plugins.dap = helpers.neovim-plugin.extraOptionsOptions // {
    enable = lib.mkEnableOption "dap";

    package = helpers.mkPluginPackageOption "dap" pkgs.vimPlugins.nvim-dap;

    adapters = helpers.mkCompositeOption "Dap adapters." {
      executables = dapHelpers.mkAdapterOption "executable" dapHelpers.executableAdapterOption;
      servers = dapHelpers.mkAdapterOption "server" dapHelpers.serverAdapterOption;
    };

    configurations =
      helpers.mkNullOrOption (with lib.types; attrsOf (listOf dapHelpers.configurationOption))
        ''
          Debuggee configurations, see `:h dap-configuration` for more info.
        '';

    signs = helpers.mkCompositeOption "Signs for dap." {
      dapBreakpoint = dapHelpers.mkSignOption "B" "Sign for breakpoints.";

      dapBreakpointCondition = dapHelpers.mkSignOption "C" "Sign for conditional breakpoints.";

      dapLogPoint = dapHelpers.mkSignOption "L" "Sign for log points.";

      dapStopped = dapHelpers.mkSignOption "→" "Sign to indicate where the debuggee is stopped.";

      dapBreakpointRejected = dapHelpers.mkSignOption "R" "Sign to indicate breakpoints rejected by the debug adapter.";
    };

    extensionConfigLua = lib.mkOption {
      type = lib.types.lines;
      description = ''
        Extension configuration for dap. Don't use this directly !
      '';
      default = "";
      internal = true;
    };
  };

  config =
    let
      options =
        with cfg;
        {
          inherit configurations;

          adapters =
            (lib.optionalAttrs (adapters.executables != null) (
              dapHelpers.processAdapters "executable" adapters.executables
            ))
            // (lib.optionalAttrs (adapters.servers != null) (
              dapHelpers.processAdapters "server" adapters.servers
            ));

          signs = with signs; {
            DapBreakpoint = dapBreakpoint;
            DapBreakpointCondition = dapBreakpointCondition;
            DapLogPoint = dapLogPoint;
            DapStopped = dapStopped;
            DapBreakpointRejected = dapBreakpointRejected;
          };
        }
        // cfg.extraOptions;
    in
    lib.mkIf cfg.enable {
      extraPlugins = [ cfg.package ];

      extraConfigLua =
        (lib.optionalString (cfg.adapters != null) ''
          require("dap").adapters = ${helpers.toLuaObject options.adapters}
        '')
        + (lib.optionalString (options.configurations != null) ''
          require("dap").configurations = ${helpers.toLuaObject options.configurations}
        '')
        + (lib.optionalString (cfg.signs != null) ''
          local __dap_signs = ${helpers.toLuaObject options.signs}
          for sign_name, sign in pairs(__dap_signs) do
            vim.fn.sign_define(sign_name, sign)
          end
        '')
        + cfg.extensionConfigLua;
    };
}
