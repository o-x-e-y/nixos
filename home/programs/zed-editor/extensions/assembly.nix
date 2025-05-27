{
  buildZedExtension,
  buildZedGrammar,
  fetchFromGitHub,
}:
let
  asm-grammar = buildZedGrammar {
    name = "asm";
    version = "0.1.0";
    
    src = fetchFromGitHub {
      owner = "RubixDev";
      repo = "tree-sitter-asm";
      rev = "6ace266be7ad6bf486a95427ca3fc949aff66211";
      hash = "sha256-sMUlk4BKpsmNhGF/ayi/wkSP6ea7pvTJKuctnOvKda0=";
    };
  };
in
buildZedExtension (finalAttrs: {
  name = "Assembly";
  version = "0.0.2";

  src = fetchFromGitHub {
    owner = "o-x-e-y";
    repo = "zed-asm";
    rev = "743de05d7a36ec96af79b77f5d8315979016bcca";
    hash = "sha256-oLkYwq/yzV6YDcYNSx659cHPbecNV2L1vr3PCTeGOn0=";
  };
  
  grammars = [ asm-grammar ];
})