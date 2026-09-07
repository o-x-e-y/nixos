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

  nix.nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];

  nixpkgs.config.allowUnfree = true;
}
