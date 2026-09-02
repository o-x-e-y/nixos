{ lib }:

# A YAML emitter for cordis.patch.yml that can carry `!!js` tags.
#
# lib.generators.toYAML is builtins.toJSON, so a `!!js` string comes out quoted
# and inert -- which is why the patch has to be a hand-written string today.
# This renders block YAML instead and treats a `js` marker as a real tag.
rec {
  # Mark a value as a raw `!!js` expression rather than a string.
  js = expr: { __dshJs = expr; };

  isJs = v: builtins.isAttrs v && v ? __dshJs;

  indent = n: lib.concatStrings (lib.genList (_: "  ") n);

  # Strings go through toJSON: JSON scalars are valid YAML, and this gets the
  # escaping right for free (quotes, backslashes, newlines, leading `!`).
  scalar =
    v:
    if v == null then
      "null"
    else if builtins.isBool v then
      (if v then "true" else "false")
    else if builtins.isInt v || builtins.isFloat v then
      toString v
    else if builtins.isString v then
      builtins.toJSON v
    else
      throw "cordis: cannot render ${builtins.typeOf v} as a YAML scalar";

  isLeaf = v: isJs v || !(builtins.isAttrs v || builtins.isList v);

  # Renders `v` as the right-hand side of `key:` or a `-` bullet. Leaves stay on
  # the same line; containers break to the next and indent.
  value =
    depth: v:
    if isJs v then
      " !!js ${v.__dshJs}"
    else if builtins.isList v then
      (if v == [ ] then " []" else "\n" + list (depth + 1) v)
    else if builtins.isAttrs v then
      (if v == { } then " {}" else "\n" + mapping (depth + 1) v)
    else
      " " + scalar v;

  list =
    depth: items:
    lib.concatStringsSep "\n" (
      map (
        item:
        if isLeaf item then
          "${indent depth}- ${lib.removePrefix " " (value depth item)}"
        else
          # A container under a bullet: render it one level in, then let the
          # dash occupy the first two columns of its first line. Every later
          # line keeps that indent, which is exactly where `- ` leaves them.
          "${indent depth}- "
          + lib.removePrefix (indent (depth + 1)) (
            if builtins.isList item then list (depth + 1) item else mapping (depth + 1) item
          )
      ) items
    );

  # Keys are quoted unconditionally. YAML 1.1 resolves a bare `off`, `no`, `y`,
  # `on` and friends to booleans in key position as much as in value position --
  # the hand-written patch already had to quote `"off"` for the qwen route's
  # reasoningEfforts -- and quoting every key removes the whole class of
  # surprise rather than maintaining a list of reserved words.
  mapping =
    depth: attrs:
    lib.concatStringsSep "\n" (
      lib.mapAttrsToList (name: v: "${indent depth}${scalar name}:${value depth v}") attrs
    );

  # The whole file: a cordis patch is a YAML sequence of operations.
  render = rows: list 0 rows + "\n";

}
