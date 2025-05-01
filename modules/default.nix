{ ... }:
{
  imports = [
    ./kanata.nix
    ./zed-editor.nix
    # Other modules
  ];
}

# { ... }:
# let
#   kanataPath = ./kanata/default.nix;
# in
# {
#   imports = builtins.trace "Kanata path: ${toString kanataPath}" [
#     kanataPath
#     # Other modules
#   ];
# }

# {
#   imports = [
#     ./kanata/kanata.nix
#     # ./zed-editor/zed-editor.nix
#   ];
# }