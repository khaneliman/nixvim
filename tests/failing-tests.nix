{
  pkgs,
  linkFarmFromDrvs,
  runCommandLocal,
  mkTestDerivationFromNixvimModule,
}:
let
  # Wraps a call to mkTestDerivationFromNixvimModule with testers.testBuildFailure
  mkFailingNixvimTest =
    args: pkgs.testers.testBuildFailure (mkTestDerivationFromNixvimModule ({ inherit pkgs; } // args));

  pluginStubs = pkgs.callPackage ./utils/plugin-stubs.nix { };

  combineConflictDep = pluginStubs.mkPlugin "combine-conflict-dep" { };
  combineConflictDepOverride = combineConflictDep.overrideAttrs (old: {
    postInstall = ''
      ${old.postInstall or ""}
      touch $out/conflict-marker
    '';
  });
  combineConflictRootA = pluginStubs.mkPlugin "combine-conflict-root-a" {
    dependencies = [ combineConflictDep ];
  };
  combineConflictRootB = pluginStubs.mkPlugin "combine-conflict-root-b" {
    dependencies = [ combineConflictDepOverride ];
  };
in
linkFarmFromDrvs "failing-tests" [
  (runCommandLocal "fail-running-nvim"
    {
      failed = mkFailingNixvimTest {
        name = "prints-hello-world";
        module = {
          extraConfigLua = ''
            print('Hello, world!')
          '';
        };
      };
    }
    ''
      [[ 1 = $(cat "$failed/testBuildFailure.exit") ]]
      grep -F 'ERROR: Hello, world!' "$failed/testBuildFailure.log"
      touch $out
    ''
  )
  (runCommandLocal "fail-on-warnings"
    {
      failed = mkFailingNixvimTest {
        name = "warns-hello-world";
        module = {
          warnings = [ "Hello, world!" ];
        };
      };
    }
    ''
      [[ 1 = $(cat "$failed/testBuildFailure.exit") ]]
      grep -F 'Failed 1 expectation' "$failed/testBuildFailure.log"
      grep -F 'Expected length to be 0 but found 1.' "$failed/testBuildFailure.log"
      grep -F 'For warnings' "$failed/testBuildFailure.log"
      grep -F 'Hello, world!' "$failed/testBuildFailure.log"
      touch $out
    ''
  )
  (runCommandLocal "fail-on-assertions"
    {
      failed = mkFailingNixvimTest {
        name = "asserts-hello-world";
        module = {
          assertions = [
            {
              assertion = false;
              message = "Hello, world!";
            }
          ];
        };
      };
    }
    ''
      [[ 1 = $(cat "$failed/testBuildFailure.exit") ]]
      grep -F 'Failed 1 expectation' "$failed/testBuildFailure.log"
      grep -F 'Expected length to be 0 but found 1.' "$failed/testBuildFailure.log"
      grep -F 'For assertions' "$failed/testBuildFailure.log"
      grep -F 'Hello, world!' "$failed/testBuildFailure.log"
      touch $out
    ''
  )
  (runCommandLocal "fail-on-ambiguous-combine-plugin-dependency"
    {
      failed = mkFailingNixvimTest {
        name = "ambiguous-combine-plugin-dependency";
        module = {
          performance.combinePlugins.enable = true;
          extraPlugins = [
            combineConflictRootA
            combineConflictRootB
          ];
        };
      };
    }
    ''
      [[ 1 = $(cat "$failed/testBuildFailure.exit") ]]
      grep -F 'combinePlugins: found multiple derivations named combine-conflict-dep' "$failed/testBuildFailure.log"
      touch $out
    ''
  )
  (runCommandLocal "fail-on-ambiguous-combine-plugin-top-level"
    {
      failed = mkFailingNixvimTest {
        name = "ambiguous-combine-plugin-top-level";
        module = {
          performance.combinePlugins.enable = true;
          extraPlugins = [
            combineConflictDep
            combineConflictDepOverride
          ];
        };
      };
    }
    ''
      [[ 1 = $(cat "$failed/testBuildFailure.exit") ]]
      grep -F 'combinePlugins: found multiple derivations named combine-conflict-dep' "$failed/testBuildFailure.log"
      touch $out
    ''
  )
  (runCommandLocal "fail-on-ambiguous-combine-plugin-top-level-optional"
    {
      failed = mkFailingNixvimTest {
        name = "ambiguous-combine-plugin-top-level-optional";
        module = {
          performance.combinePlugins.enable = true;
          extraPlugins = [
            combineConflictDep
            {
              plugin = combineConflictDepOverride;
              optional = true;
            }
          ];
        };
      };
    }
    ''
      [[ 1 = $(cat "$failed/testBuildFailure.exit") ]]
      grep -F 'combinePlugins: found multiple derivations named combine-conflict-dep' "$failed/testBuildFailure.log"
      touch $out
    ''
  )
]
