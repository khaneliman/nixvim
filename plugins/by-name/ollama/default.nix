{
  lib,
  ...
}:
let
  inherit (lib.nixvim) defaultNullOpts;
  inherit (lib) types;

  actionOptionType =
    with lib.types;
    oneOf [
      rawLua
      (enum [
        "display"
        "replace"
        "insert"
        "display_replace"
        "display_insert"
        "display_prompt"
      ])
      (submodule {
        options = {
          fn = lib.nixvim.mkNullOrStrLuaFnOr (enum [ false ]) ''
            fun(prompt: table): Ollama.PromptActionResponseCallback

            Example:
            ```lua
              function(prompt)
                -- This function is called when the prompt is selected
                -- just before sending the prompt to the LLM.
                -- Useful for setting up UI or other state.

                -- Return a function that will be used as a callback
                -- when a response is received.
                ---@type Ollama.PromptActionResponseCallback
                return function(body, job)
                  -- body is a table of the json response
                  -- body.response is the response text received

                  -- job is the plenary.job object when opts.stream = true
                  -- job is nil otherwise
                end

              end
            ```
          '';

          opts = {
            stream = defaultNullOpts.mkBool false ''
              Whether to stream the response.
            '';
          };
        };
      })
    ];
in
lib.nixvim.plugins.mkNeovimPlugin {
  name = "ollama";
  packPathName = "ollama.nvim";
  package = "ollama-nvim";

  maintainers = [ lib.maintainers.GaetanLepage ];

  settingsOptions = {
    model = defaultNullOpts.mkStr "mistral" ''
      The default model to use.
    '';

    prompts =
      let
        promptOptions = {
          prompt = lib.mkOption {
            type = with lib.types; maybeRaw str;
            description = ''
              The prompt to send to the model.

              Replaces the following tokens:
              - `$input`: The input from the user
              - `$sel`: The currently selected text
              - `$ftype`: The filetype of the current buffer
              - `$fname`: The filename of the current buffer
              - `$buf`: The contents of the current buffer
              - `$line`: The current line in the buffer
              - `$lnum`: The current line number in the buffer
            '';
          };

          inputLabel = defaultNullOpts.mkStr "> " ''
            The label to use for an input field.
          '';

          action = lib.nixvim.mkNullOrOption actionOptionType ''
            How to handle the output.

            See [here](https://github.com/nomnivore/ollama.nvim/tree/main#actions) for more details.

            Defaults to the value of `plugins.ollama.action`.
          '';

          model = lib.nixvim.mkNullOrStr ''
            The model to use for this prompt.

            Defaults to the value of `plugins.ollama.model`.
          '';

          extract =
            defaultNullOpts.mkNullable (with lib.types; maybeRaw (either str (enum [ false ])))
              "```$ftype\n(.-)```"
              ''
                A `string.match` pattern to use for an Action to extract the output from the response
                (Insert/Replace).
              '';

          options = lib.nixvim.mkNullOrOption (with types; attrsOf anything) ''
            Additional model parameters, such as temperature, listed in the documentation for the [Modelfile](https://github.com/jmorganca/ollama/blob/main/docs/modelfile.md#valid-parameters-and-values).
          '';

          system = lib.nixvim.mkNullOrStr ''
            The SYSTEM instruction specifies the system prompt to be used in the Modelfile template,
            if applicable.
            (overrides what's in the Modelfile).
          '';

          format = lib.nixvim.defaultNullOpts.mkEnumFirstDefault [ "json" ] ''
            The format to return a response in.
            Currently the only accepted value is `"json"`.
          '';
        };
      in
      lib.mkOption {
        type = with types; attrsOf (either (submodule { options = promptOptions; }) (enum [ false ]));
        default = { };
        description = ''
          A table of prompts to use for each model.
          Default prompts are defined [here](https://github.com/nomnivore/ollama.nvim/blob/main/lua/ollama/prompts.lua).
        '';
      };

    action = defaultNullOpts.mkNullable actionOptionType "display" ''
      How to handle prompt outputs when not specified by prompt.
      See [here](https://github.com/nomnivore/ollama.nvim/tree/main#actions) for more details.
    '';

    url = defaultNullOpts.mkStr "http://127.0.0.1:11434" ''
      The url to use to connect to the ollama server.
    '';

    serve = {
      on_start = defaultNullOpts.mkBool false ''
        Whether to start the ollama server on startup.
      '';
      command = defaultNullOpts.mkStr "ollama" ''
        The command to use to start the ollama server.
      '';
      args = defaultNullOpts.mkListOf types.str [ "serve" ] ''
        The arguments to pass to the serve command.
      '';
      stop_command = defaultNullOpts.mkStr "pkill" ''
        The command to use to stop the ollama server.
      '';
      stop_args = defaultNullOpts.mkListOf types.str [ "-SIGTERM" "ollama" ] ''
        The arguments to pass to the stop command.
      '';
    };
  };

  settingsExample = {
    settings = {
      model = "mistral";
      serve = {
        on_start = false;
        command = "ollama";
        args = [ "serve" ];
        stop_command = "pkill";
        stop_args = [
          "-SIGTERM"
          "ollama"
        ];
      };
      action = "display";
      url = "http://127.0.0.1:11434";
    };
  };

  # TODO: Deprecated in 2025-02-01
  inherit (import ./deprecations.nix) deprecateExtraOptions optionsRenamedToSettings;
}
