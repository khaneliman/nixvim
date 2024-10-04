{ lib, ... }:
let
  inherit (lib)
    add
    attrNames
    elemAt
    foldl'
    genList
    length
    replaceStrings
    sort
    toLower
    trace
    ;

  maintainers = import ../../lib/maintainers.nix;
  simplify =
    replaceStrings
      [
        "-"
        "_"
      ]
      [
        ""
        ""
      ];

  namesSorted = sort (a: b: a.key < b.key) (
    map (
      n:
      let
        pos = builtins.unsafeGetAttrPos n maintainers;
      in
      assert pos == null -> throw "maintainers entry ${n} is malformed";
      {
        name = n;
        line = pos.line;
        key = toLower (simplify n);
      }
    ) (attrNames maintainers)
  );
  before =
    {
      name,
      line,
      key,
    }:
    foldl' (
      acc: n: if n.key < key && (acc == null || n.key > acc.key) then n else acc
    ) null namesSorted;
  errors = foldl' add 0 (
    map (
      i:
      let
        a = elemAt namesSorted i;
        b = elemAt namesSorted (i + 1);
        lim =
          let
            t = before a;
          in
          if t == null then "the initial {" else t.name;
      in
      if a.line >= b.line then
        trace (
          "maintainer ${a.name} (line ${toString a.line}) should be listed "
          + "after ${lim}, not after ${b.name} (line ${toString b.line})"
        ) 1
      else
        0
    ) (genList (i: i) (length namesSorted - 1))
  );
in
if errors == 0 then
  builtins.toJSON { success = true; }
else
  builtins.toJSON {
    success = false;
    error = "maintainers.nix is not sorted correctly";
  }
