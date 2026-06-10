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
        nixfmt
        package-version-server
        zig
        ruff
        lldb
        vscode-extensions.vadimcn.vscode-lldb
        vtsls
        jdk
      ];
    };

    programs.zed-editor-extensions = {
      enable = true;
      packages =
        with pkgs.zed-extensions;
        [
          awk
          bqn
          # csharp
          dbml
          docker-compose
          env
          html
          http
          # java
          jetbrains-icons
          kconfig
          latex
          live-server
          make
          nix
          plantuml
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
