{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.apps.zed-editor;
  asm = pkgs.callPackage ./assembly.nix { };
in
{  
  config = lib.mkIf (cfg.enable && cfg.useExtensions) {
    programs.zed-editor = {
      extraPackages = with pkgs; [
        nixd
        nixfmt-rfc-style
        python313
        rust-analyzer
        package-version-server
        zig
      ];
    };

    programs.zed-editor-extensions = {
      enable = true;
      packages = with pkgs.zed-extensions; [
        awk
        bqn
        csharp
        dbml
        dockerfile
        env
        html
        http
        jetbrains-icons
        kconfig
        latex
        make
        nix
        pylsp
        python-refactoring
        python-requirements
        rainbow-csv
        scss
        sql
        toml
        typst
        zig
      ] ++ [
        asm
      ];
    };
  };
}
