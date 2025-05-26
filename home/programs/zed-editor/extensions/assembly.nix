{
  buildZedExtension,
  fetchFromGitHub,
}:

buildZedExtension (finalAttrs: {
  name = "Assembly Syntax";
  version = "0.0.1";

  src = fetchFromGitHub {
    owner = "DevBlocky";
    repo = "zed-asm";
    rev = "v${finalAttrs.version}";
    hash = "sha256-1S4I9fJyShkrBUqGaF8BijyRJfBgVh32HLn1ZoNlnsU=";
  };
})