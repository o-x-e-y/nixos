{
  config,
  lib,
  pkgs,
  mainUser,
  osConfig,
  ...
}:
let
  cfg = config.apps.git;
in
{
  options.apps.git = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable git settings";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.git = {
      enable = true;
      settings = {
        user = {
          name = "${mainUser.username}";
          email = "lucoerlemans37@gmail.com";
        };
        init.defaultBranch = "main";
        core.editor = "codium --wait";
        merge.ff = true;
        url."git@github.com:".insteadOf = "https://github.com/";
        credential."https://git.fhict.nl".helper = ''!f() { test "$1" = get && cat ${
          osConfig.sops.templates."git-credentials-fhict".path
        }; }; f'';
      };
      signing.format = null;
    };

    programs.delta = {
      enable = true;
      enableGitIntegration = true;
      options = {
        side-by-side = true;
        line-numbers = true;
        pager = "less --mouse --wheel-lines=3";
      };
    };

    home.packages = [
      (pkgs.writeShellScriptBin "git-branch-diff" ''
        set -eu

        base_branch="''${1:-main}"

        current_branch="$(git branch --show-current)"

        if [ -z "$current_branch" ]; then
          echo "Error: not on a branch or not inside a git repo." >&2
          exit 1
        fi

        echo "''${base_branch}...''${current_branch}"
        git rev-list --left-right --count "''${base_branch}...''${current_branch}"
      '')
      (pkgs.writeShellScriptBin "git-bd" ''git-branch-diff "$@"'')
    ];
  };
}
