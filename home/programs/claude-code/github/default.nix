{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.apps.claude-code;

  # A fine-grained PAT, not a `gh auth login` session: its repository list IS
  # the "which repos" answer, enforced by GitHub rather than by the permission
  # rules below -- those match command prefixes and cannot see which repo gh
  # resolves from the cwd or `-R`. Read at call time so the token never lands in
  # the store, and skipped when the secret is absent so gh still runs (and the
  # home-manager activation's `gh help` still works) before it exists.
  # A repo's direnv can set GH_TOKEN_FILE to another sops secret (e.g. an
  # org-scoped PAT); it names a file rather than holding the token, so the token
  # itself never sits in the shell environment.
  tokenFile = "/run/secrets/github_token";

  gh = pkgs.symlinkJoin {
    name = "gh";
    paths = [ pkgs.gh ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/gh \
        --run 'f="''${GH_TOKEN_FILE:-${tokenFile}}"; if [ -r "$f" ]; then export GH_TOKEN="$(< "$f")"; fi'
    '';
    meta.mainProgram = "gh";
  };
in
{
  config = lib.mkIf cfg.enable {
    programs.gh = {
      enable = true;
      package = gh;
      # Matches the url.insteadOf rewrite in ../../git: clones go over SSH.
      settings.git_protocol = "ssh";
    };

    # Lists merge across modules, so these append to the allow/ask/deny lists in
    # ../default.nix rather than replacing them.
    programs.claude-code.settings.permissions = {
      # Reading issues, PRs and CI runs is how Claude finds out what to work on.
      allow = [
        "Bash(gh issue list:*)"
        "Bash(gh issue view:*)"
        "Bash(gh issue status:*)"
        "Bash(gh pr list:*)"
        "Bash(gh pr view:*)"
        "Bash(gh pr diff:*)"
        "Bash(gh pr checks:*)"
        "Bash(gh pr status:*)"
        "Bash(gh repo view:*)"
        "Bash(gh run list:*)"
        "Bash(gh run view:*)"
        "Bash(gh label list:*)"
        "Bash(gh search:*)"
        "Bash(gh auth status:*)"
      ];

      # Everything here is visible to other people on the repo, so it is gated
      # rather than allowed, as with ../intervals-icu's upload. `gh api` sits
      # here too: it can reach any endpoint the token can, reads and writes
      # alike, so a prefix rule cannot tell the two apart.
      ask = [
        "Bash(gh issue create:*)"
        "Bash(gh issue close:*)"
        "Bash(gh issue reopen:*)"
        "Bash(gh issue comment:*)"
        "Bash(gh issue edit:*)"
        "Bash(gh pr create:*)"
        "Bash(gh pr comment:*)"
        "Bash(gh pr edit:*)"
        "Bash(gh pr review:*)"
        "Bash(gh pr close:*)"
        "Bash(gh pr merge:*)"
        "Bash(gh api:*)"
      ];

      # The token should not carry the scopes for these in the first place;
      # this is the second lock.
      deny = [
        "Bash(gh repo delete:*)"
        "Bash(gh issue delete:*)"
        "Bash(gh release delete:*)"
        "Bash(gh secret:*)"
        "Bash(gh auth login:*)"
        "Bash(gh auth logout:*)"
      ];
    };
  };
}
