{
  empty = {
    plugins.codesnap.enable = true;
  };

  defaults = {
    plugins.codesnap = {
      enable = true;

      settings = {
        show_line_number = true;
        highlight_color = "#ffffff20";
        show_workspace = true;
        snapshot_config = {
          theme = "candy";
          window = {
            mac_window_bar = true;
            shadow = {
              radius = 20;
              color = "#00000040";
            };
            margin = {
              x = 82;
              y = 82;
            };
            border = {
              width = 1;
              color = "#ffffff30";
            };
            title_config = {
              color = "#ffffff";
              font_family = "Pacifico";
            };
          };
          themes_folders = { };
          fonts_folders = { };
          line_number_color = "#495162";
          command_output_config = {
            prompt = "❯";
            font_family = "CaskaydiaCove Nerd Font";
            prompt_color = "#F78FB3";
            command_color = "#98C379";
            string_arg_color = "#ff0000";
          };
          code_config = {
            font_family = "CaskaydiaCove Nerd Font";
            breadcrumbs = {
              enable = true;
              separator = "/";
              color = "#80848b";
              font_family = "CaskaydiaCove Nerd Font";
            };
          };
          watermark = {
            content = "CodeSnap.nvim";
            font_family = "Pacifico";
            color = "#ffffff";
          };
          background = {
            start = {
              x = 0;
              y = 0;
            };
            end = {
              x = "max";
              y = 0;
            };
            stops = [
              {
                position = 0;
                color = "#6bcba5";
              }
              {
                position = 1;
                color = "#caf4c2";
              }
            ];
          };
        };
      };
    };
  };

  example = {
    plugins.codesnap = {
      enable = true;

      settings = {
        save_path = "~/Pictures/Screenshots/";
        mac_window_bar = true;
        title = "CodeSnap.nvim";
        watermark = "";
        breadcrumbs_separator = "/";
        has_breadcrumbs = true;
        has_line_number = false;
      };
    };
  };
}
