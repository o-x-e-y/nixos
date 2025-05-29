{
  buildZedExtension,
  buildZedGrammar,
  fetchFromGitHub,
}:
let
  asm-grammar = buildZedGrammar (finalAttrs: {
    name = "asm";
    version = "6ace266be7ad6bf486a95427ca3fc949aff66211";

    src = fetchFromGitHub {
      owner = "RubixDev";
      repo = "tree-sitter-asm";
      rev = finalAttrs.version;
      hash = "sha256-sMUlk4BKpsmNhGF/ayi/wkSP6ea7pvTJKuctnOvKda0=";
    };
  });
in
buildZedExtension (finalAttrs: {
  name = "zed-asm";
  version = "0.0.2";

  src = fetchFromGitHub {
    owner = "o-x-e-y";
    repo = "zed-asm";
    rev = "v${finalAttrs.version}";
    hash = "sha256-oLkYwq/yzV6YDcYNSx659cHPbecNV2L1vr3PCTeGOn0=";
  };

  grammars = [ asm-grammar ];
})
