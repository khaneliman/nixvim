{
  lib,
  callPackage,
  pathsToLink,
  standalonePlugins,
}:
let
  inherit (import ./utils.nix lib)
    getAndNormalizeDeps
    removeDeps
    ;
  mkPluginPack = callPackage ./mk-plugin-pack.nix { inherit lib; };

  pluginIdentity = p: toString p.plugin;
  groupByName = plugins: builtins.groupBy (p: lib.getName p.plugin) plugins;

  mergeDuplicatedPlugins =
    topLevelPlugins: plugins:
    let
      pluginsByName = groupByName plugins;
      topLevelPluginsByName = groupByName topLevelPlugins;
      pluginNames = lib.attrNames pluginsByName;
      conflictAssertions = map (
        name:
        let
          entries = pluginsByName.${name};
          identities = lib.unique (map pluginIdentity entries);
          topLevelEntries = topLevelPluginsByName.${name} or [ ];
          topLevelIdentities = lib.unique (map pluginIdentity topLevelEntries);
        in
        {
          assertion = builtins.length identities == 1 || builtins.length topLevelIdentities == 1;
          message = ''
            combinePlugins: found multiple derivations named ${name}.

            Set one configured top-level package for ${name}, or use the same package everywhere.
          '';
        }
      ) pluginNames;
      mergePlugin =
        name:
        let
          entries = pluginsByName.${name};
          identities = lib.unique (map pluginIdentity entries);
          topLevelEntries = topLevelPluginsByName.${name} or [ ];
          topLevelIdentities = lib.unique (map pluginIdentity topLevelEntries);
          firstStartPlugin = lib.findFirst (p: !p.optional) null entries;
          representative =
            if builtins.length topLevelIdentities == 1 then
              lib.findFirst (p: pluginIdentity p == builtins.head topLevelIdentities) null topLevelEntries
            else if builtins.length identities == 1 then
              builtins.head entries
            else
              builtins.head entries;
          configs = builtins.filter (config: config != null && config != "") (
            builtins.catAttrs "config" entries
          );
        in
        representative
        // {
          optional = firstStartPlugin == null;
          config = if configs == [ ] then null else builtins.concatStringsSep "\n" configs;
        };
    in
    {
      plugins = map mergePlugin pluginNames;
      assertions = conflictAssertions;
    };

in
/*
  *combinePlugins* function

  Take a list of combined plugins, combine the relevant ones and return the resulting list of plugins
*/
normalizedPlugins:
let
  # Plugin list extended with dependencies
  allPlugins =
    let
      pluginWithItsDeps = p: [ p ] ++ builtins.concatMap pluginWithItsDeps (getAndNormalizeDeps p);
    in
    mergeDuplicatedPlugins normalizedPlugins (builtins.concatMap pluginWithItsDeps normalizedPlugins);

  # Separated start and opt plugins
  partitionedOptStartPlugins = builtins.partition (p: p.optional) allPlugins.plugins;
  startPlugins = partitionedOptStartPlugins.wrong;
  # Remove opt plugin dependencies since they are already available in start plugins
  optPlugins = removeDeps partitionedOptStartPlugins.right;

  # Test if plugin shouldn't be included in plugin pack
  standaloneNames = map (p: if builtins.isString p then p else lib.getName p) standalonePlugins;
  isStandalone = p: builtins.elem (lib.getName p.plugin) standaloneNames;

  # Separated standalone and combined start plugins
  partitionedStandaloneStartPlugins = builtins.partition isStandalone startPlugins;
  pluginsToCombine = partitionedStandaloneStartPlugins.wrong;
  # Remove standalone plugin dependencies since they are already available in start plugins
  standaloneStartPlugins = removeDeps partitionedStandaloneStartPlugins.right;

  # Combine start plugins into a single pack
  pluginPack = mkPluginPack { inherit pluginsToCombine pathsToLink; };
in
# Combined plugins
{
  plugins = [ pluginPack ] ++ standaloneStartPlugins ++ optPlugins;
  inherit (allPlugins) assertions;
}
