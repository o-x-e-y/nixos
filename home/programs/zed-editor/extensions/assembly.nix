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
  name = "assembly-syntax";
  version = "18845e09eabba843a6d3a63cd46f2512e6531f06";

  src = fetchFromGitHub {
    owner = "DevBlocky";
    repo = "zed-asm";
    rev = finalAttrs.version;
    hash = "sha256-lh6uP/HFBrw09Qy0gL2c28K09IZCVju7s8c56g/zKVI=";
  };

  grammars = [ asm-grammar ];
})
