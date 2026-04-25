{ lib, pkgs }:
let
  pluginStubs = pkgs.callPackage ../../utils/plugin-stubs.nix { };
  byteCompileDep = pluginStubs.mkPlugin "byte-compile-dependency" { };
  byteCompileLeaf = pluginStubs.mkPlugin "byte-compile-leaf" { };
  byteCompileRoot = pluginStubs.mkPlugin "byte-compile-root" {
    dependencies = [
      byteCompileDep
      byteCompileLeaf
    ];
  };
  dedupPlugin = pluginStubs.mkPlugin "combine-dedup-plugin" { };
  canonicalDep = pluginStubs.mkPlugin "combine-canonical-dep" { };
  canonicalDepOverride = canonicalDep.overrideAttrs (old: {
    postInstall = ''
      ${old.postInstall or ""}
      echo "return 'canonical'" >$out/lua/combine-canonical-dep/canonical.lua
    '';
  });
  canonicalRoot = pluginStubs.mkPlugin "combine-canonical-root" {
    dependencies = [ canonicalDep ];
  };
  canonicalOptionalDep = pluginStubs.mkPlugin "combine-canonical-optional-dep" { };
  canonicalOptionalDepOverride = canonicalOptionalDep.overrideAttrs (old: {
    postInstall = ''
      ${old.postInstall or ""}
      echo "return 'canonical-optional'" >$out/lua/combine-canonical-optional-dep/canonical.lua
    '';
  });
  canonicalOptionalRoot = pluginStubs.mkPlugin "combine-canonical-optional-root" {
    dependencies = [ canonicalOptionalDep ];
  };

  expectNPlugins =
    config: type: n:
    let
      rawPlugins = config.build.nvimPackage.packpathDirs.myNeovimPackages.${type};
      plugins = builtins.filter (
        p:
        let
          name = lib.getName p;
        in
        name != "nvim-config" && name != lib.getName config.build.extraFiles
      ) rawPlugins;
      numPlugins = builtins.length plugins;
    in
    {
      assertion = numPlugins == n;
      message = "Expected ${toString n} '${type}' plugins, got ${toString numPlugins}: ${
        lib.concatMapStringsSep ", " lib.getName plugins
      }.";
    };
in
{
  byte-compile-excludes-dependencies =
    { config, ... }:
    let
      pluginWithDep = lib.findFirst (plugin: lib.getName plugin == "byte-compile-root") null (
        builtins.catAttrs "plugin" config.build.plugins
      );
      pluginDep = lib.findFirst (plugin: lib.getName plugin == "byte-compile-dependency") null (
        pluginWithDep.dependencies or [ ]
      );
    in
    {
      # This case avoids luajit plugin LuaRocks fixtures, which currently
      # fail to build in this environment due rockspec format mismatches.
      performance.byteCompileLua = {
        enable = true;
        plugins = true;
        excludedPlugins = [
          "byte-compile-dependency"
          "byte-compile-leaf"
        ];
      };

      extraPlugins = [ byteCompileRoot ];

      extraConfigLuaPost = ''
        local function isByteCompiled(filename)
          local f = assert(io.open(filename, "rb"))
          local data = assert(f:read(3))
          f:close()
          return data == string.char(0x1b, 0x4c, 0x4a)
        end

        local rootFile = assert(vim.api.nvim_get_runtime_file("lua/byte-compile-root/init.lua", false)[1], "byte-compile-root.lua missing")
        local depFile = assert(vim.api.nvim_get_runtime_file("lua/byte-compile-dependency/init.lua", false)[1], "byte-compile-dependency.lua missing")
        local leafFile = assert(vim.api.nvim_get_runtime_file("lua/byte-compile-leaf/init.lua", false)[1], "byte-compile-leaf.lua missing")

        assert(isByteCompiled(rootFile), "byte-compile-root should be byte-compiled")
        assert(not isByteCompiled(depFile), "excluded dependency byte-compile-dependency should not be byte-compiled")
        assert(not isByteCompiled(leafFile), "excluded dependency byte-compile-leaf should not be byte-compiled")
      '';

      assertions = [
        {
          assertion = pluginWithDep != null;
          message = "Expected top-level byte-compile-root plugin to be present in config.build.plugins.";
        }
        {
          assertion = pluginDep != null;
          message = "Expected dependency byte-compile-dependency to be present in root plugin dependencies.";
        }
        {
          assertion = lib.any (x: lib.getName x == "byte-compile-leaf") pluginWithDep.dependencies or [ ];
          message = "Expected leaf byte-compile-leaf to be present in root plugin dependencies.";
        }
      ];
    };

  combine-deduplicates-start-and-optional =
    { config, ... }:
    {
      performance.combinePlugins.enable = true;

      extraPlugins = [
        {
          plugin = dedupPlugin;
          config = "let g:combine_dedup_plugin_start_config = 1";
        }
        {
          plugin = dedupPlugin;
          optional = true;
          config = "let g:combine_dedup_plugin_duplicate_config = 1";
        }
      ];

      extraConfigLuaPost = ''
        local paths = vim.api.nvim_get_runtime_file("lua/combine-dedup-plugin/init.lua", true)
        assert(#paths == 1, "expected one runtime copy of combine-dedup-plugin, got " .. #paths)
        assert(vim.g.combine_dedup_plugin_start_config == 1, "expected start duplicate plugin config to be preserved")
        assert(vim.g.combine_dedup_plugin_duplicate_config == 1, "expected duplicate plugin config to be preserved")
      '';

      assertions = [
        (expectNPlugins config "start" 1)
        (expectNPlugins config "opt" 0)
      ];
    };

  combine-accepts-identical-top-level-derivations =
    { config, ... }:
    {
      performance.combinePlugins.enable = true;

      extraPlugins = [
        dedupPlugin
        dedupPlugin
      ];

      assertions = [
        (expectNPlugins config "start" 1)
        (expectNPlugins config "opt" 0)
      ];
    };

  combine-prefers-top-level-package-over-dependency =
    { config, ... }:
    {
      performance.combinePlugins.enable = true;

      extraPlugins = [
        canonicalRoot
        canonicalDepOverride
      ];

      extraConfigLuaPost = ''
        assert(require("combine-canonical-dep.canonical") == "canonical", "expected top-level package override to win")
      '';

      assertions = [
        (expectNPlugins config "start" 1)
        (expectNPlugins config "opt" 0)
      ];
    };

  combine-prefers-top-level-optional-over-dependency =
    { config, ... }:
    {
      performance.combinePlugins.enable = true;

      extraPlugins = [
        canonicalOptionalRoot
        {
          plugin = canonicalOptionalDepOverride;
          optional = true;
        }
      ];

      extraConfigLuaPost = ''
        assert(require("combine-canonical-optional-dep.canonical") == "canonical-optional", "expected optional top-level package override to win")
      '';

      assertions = [
        (expectNPlugins config "start" 1)
        (expectNPlugins config "opt" 0)
      ];
    };
}
