# What the auto mode classifier is told about this machine, plus a few rule
# tweaks. `/auto-mode-setup` drafts this and saves it into
# ~/.claude/settings.json, which here is a read-only store symlink -- so the
# save fails, and the startup offer to run it keeps coming back for as long as
# `environment` is empty. Setting it here settles both.
#
# To redraft, run the non-interactive form, which only prints a proposal:
#
#   claude -p "/auto-mode-setup --wizard posture=mixed scope=all depth=both --propose"
#
# and port what holds up by hand. The scan reads shell history and every repo
# under $HOME, and this file lands in a public repo: keep it to what the repo
# already makes public -- no school hosts, student numbers, emails, or anything
# read out of a remote URL. The first draft also needed rescoping (it was run
# from ~/nixos, but scope=all makes it global) and lost two allow rules:
# `Bash(nix-shell:*)` runs any command, and `rebuild` is an interactive alias
# for sudo, which Claude's shell can neither see nor authenticate.
{
  environment = [
    "### Org-wide"
    "**Organization**: None — a personal machine, no employer or organization account"
    "**Cloud provider(s)**: None configured"
    "**Repository visibility**: Every repository under github.com/o-x-e-y is public (confirmed via gh) — any push there is publishing. Other clones under ~/Repos belong to other accounts; pushing to them publishes to someone else's project"
    "**Internal sharing / snippet hosting**: None configured — treat public paste/gist services as outside the trust boundary"
    "**Secrets management**: sops-nix with an age key. `secrets/secrets.yaml` in the NixOS config repo is encrypted and committed to the public repo by design; `hosts/default/secrets.nix` declares where each value is decrypted to at activation (/run/secrets, or a declared path such as an SSH key). Decrypted values and the age key are credentials"
    "**Default / protected branches**: `main`; o-x-e-y/nixos has no branch protection or rulesets (confirmed via gh) — a push lands directly on the published branch"
    "**CI/CD deploy targets**: None configured"
    "**Network posture**: None configured"
    "**Host containment**: None — Claude Code runs directly on the user's NixOS desktop with open internet, no VM or container; `sudo` asks for a password"
    "**Source control**: GitHub, under the personal account `o-x-e-y`; no organizations configured"
    "**Trusted internal domains**: None configured"
    "**Trusted cloud buckets**: None configured"
    "**Key internal services**: None configured"
    "**Internal package registry**: None configured"
    "**Sensitive data locations & audiences**: decrypted sops secrets (/run/secrets and the paths declared in hosts/default/secrets.nix), the sops age key under ~/.config/sops, SSH and GPG keys, ~/.claude/.credentials.json, and tokens in git remote URLs or credential helpers — audience is the user only; never print, copy, commit or upload them"
    "**Data retention / declassification**: None configured"
    "**Sensitive remote targets**: any namespace, host, or container whose name carries `prod` or `production` as a whole word or name segment"
    "**Protected deployment namespaces / environments**: None configured — fall back to the Sensitive remote targets heuristic"
    "**Protected IaC scopes**: IAM, RBAC, networking, quota, and node-pool resources; anything whose name or tag carries `prod` or `production` as a whole word or name segment"
    "### User-specific"
    "**Primary use of Claude Code**: mixed — the NixOS config at ~/nixos, hobby software projects under ~/Repos, study documents, and personal-service integrations (training platform, nutrition log, calendar) through the MCP tools and CLIs this config installs"
    "**Trusted repo**: the user's own repos under github.com/o-x-e-y, o-x-e-y/nixos foremost — the session's own work is fine to commit/push there; content ported from outside the session's repo is not its own work even if directed to port it; secrets and sensitive data are never cleared into them by virtue of visibility"
    "**Org-specific CLIs**: None organizational. Personal tools this config installs: `pathe` and `boxd` (read-only lookups of public pages), `intervals-icu` (authenticated client for the user's training calendar), `ledger` (a jrnl wrapper holding the user's work journal; `ledger --json` only reads it), and the Nix toolchain (`nix`, `nix-shell`, `nixos-rebuild`, `nixfmt`, `home-manager`) — routine for the user's own config"
  ];

  allow = [
    "$defaults"
    "NixOS Build Checks: Building or evaluating the NixOS config in ~/nixos without activating it — `nixos-rebuild build` or `dry-build`, `nix build`, `nix eval`, `nix flake check`, `nix flake show`, `home-manager build` — only writes to the Nix store and a `result` symlink, so it is routine verification. Does NOT cover `switch`, `boot`, `test`, anything under `sudo`, or `nix flake update`."
  ];

  soft_deny = [
    "$defaults"
    "Nix Generation Deletion: `nix-collect-garbage -d` or `--delete-older-than`, `nix-env --delete-generations`, `nix-store --delete`, or `home-manager expire-generations` delete old system or home-manager generations and store paths, which removes rollback targets for good. Block unless the user asked for it in this session."
    "Ledger Writes: `ledger` or `jrnl` with entry text, `--edit`, `--delete`, `--change-time`, `--import`, `--encrypt` or `--decrypt` adds to or rewrites the user's personal work journal, which is their own record. `ledger --json` is read-only and not covered. Block unless the user asked for that exact change in this session."
  ];
}
