{
  empty = {
    plugins.dap-virtual-text.enable = true;
  };

  default = {
    plugins.dap-virtual-text = {
      enable = true;

      settings = {
        enabled_commands = true;
        highlight_changed_variables = true;
        highlight_new_as_changed = true;
        show_stop_reason = true;
        commented = false;
        only_first_definition = true;
        all_references = false;
        clear_on_continue = false;
        display_callback = ''
          function(variable, buf, stackframe, node, options)
            if options.virt_text_pos == 'inline' then
              return ' = ' .. variable.value
            else
              return variable.name .. ' = ' .. variable.value
            end
          end
        '';
        virt_text_pos = "eol";
        all_frames = false;
        virt_lines = false;
      };
    };
  };

  lazy = {
    plugins = {
      lz-n.enable = true;
      dap = {
        enable = true;
        lazyLoad.settings = {
          cmd = [
            "DapContinue"
            "DapNew"
          ];
        };
      };
      dap-virtual-text = {
        enable = true;

        lazyLoad.settings = {
          before.__raw = ''
            function()
              require('lz.n').trigger_load('nvim-dap')
            end
          '';
          cmd = [
            "DapVirtualTextToggle"
            "DapVirtualTextEnable"
          ];
        };
      };
    };
    extraConfigLuaPost = ''
      vim.cmd('DapVirtualTextEnable')
    '';
  };
}
