{
  inputs,
  ...
}:
{
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # `extra-` rather than plain, so cache.nixos.org stays in the list. Without
  # this cache dsh and the tui bundle are a source build.
  nix.settings.extra-substituters = [ "https://deepseek-harness-nix.cachix.org" ];
  nix.settings.extra-trusted-public-keys = [
    "deepseek-harness-nix.cachix.org-1:5NrkwLN9veNMhiINtU5ZeV4isXFhFsOwn6Ms7J1M+TA="
  ];

  nix.settings.nix-path = [ "nixpkgs=${inputs.nixpkgs}" ];

  # Instead of nix.gc: it also drops direnv and `result` roots untouched for 30
  # days, which nix-direnv keeps fresh by touching them on every load.
  programs.nh = {
    enable = true;
    clean = {
      enable = true;
      dates = "Mon 12:00";
      extraArgs = "--keep-since 30d --keep 5";
    };
  };

  nixpkgs.config.allowUnfree = true;
}
