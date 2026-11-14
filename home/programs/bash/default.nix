{
  config,
  osConfig,
  lib,
  ...
}:
let
  cfg = config.apps.bash;
in
{
  options.apps.bash = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable bash settings";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.bash = {
      enable = true;
      historyControl = [ "ignoreboth" ]; # ignore both duplicates and space in history
      shellAliases = {
        "ls" = "ls --color=auto";
        "ll" = "ls --color=auto -l";
        "grep" = "grep --color=auto";
        "hgrep" = "history | grep";
        ".." = "cd ..";
        "rebuild" = "sudo nixos-rebuild switch --flake ~/nixos#${osConfig.networking.hostName}";
        "update" = "nix flake update --flake ~/nixos --commit-lock-file && rebuild";
        "rebuild-boot" = "sudo /nix/var/nix/profiles/system/bin/switch-to-configuration boot";
      };
    };
  };
}
