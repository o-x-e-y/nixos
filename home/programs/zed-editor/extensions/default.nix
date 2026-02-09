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
        package-version-server
        zig
        ruff
        lldb
        vscode-extensions.vadimcn.vscode-lldb
        vtsls
      ];
    };

    programs.zed-editor-extensions = {
      enable = true;
      packages =
        with pkgs.zed-extensions;
        [
          awk
          bqn
          codebook
          # color-highlight
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
          python-requirements
          rainbow-csv
          # scss
          sql
          toml
          typst
          zig
        ]
        ++ [
          asm
        ];
    };
  };
}
