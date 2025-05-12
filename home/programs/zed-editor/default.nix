{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.apps.zed-editor;
in
{
  imports = [
    ./settings.nix
    ./keymaps.nix
  ];
  
  options.apps.zed-editor = {
    enable = lib.mkEnableOption "Enable Zed Editor";
  };

  config = lib.mkIf cfg.enable {
    programs.zed-editor = {
      enable = true;
      extraPackages = with pkgs; [
        nixd
        nixfmt-rfc-style
        python314
        rust-analyzer
        package-version-server
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
      ];
    };
  };
}
