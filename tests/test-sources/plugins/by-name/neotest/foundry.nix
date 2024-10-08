{ lib, pkgs, ... }:
{
  # TODO: added 2024-09-15
  # TODO: Re-enable when upstream builds in darwin sandbox
  example = lib.mkIf pkgs.stdenv.isLinux {
    plugins = {
      treesitter.enable = true;
      neotest = {
        enable = true;

        adapters.foundry = {
          enable = true;

          settings = {
            foundryCommand = "forge test";
            foundryConfig = null;
            env = { };
            cwd.__raw = ''
              function ()
                return lib.files.match_root_pattern("foundry.toml")
              end
            '';
            filterDir.__raw = ''
              function(name)
                return (
                  name ~= "node_modules"
                  and name ~= "cache"
                  and name ~= "out"
                  and name ~= "artifacts"
                  and name ~= "docs"
                  and name ~= "doc"
                  -- and name ~= "lib"
                )
              end
            '';
          };
        };
      };
    };
  };
}
