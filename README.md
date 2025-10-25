# NixOS Configuration

My NixOS config, currently configures some kde settings, zed extensions, and kanata. Uses flakes.
To apply, simply run

```sh
nixos-rebuild switch --flake .#nixos
```



Assuming you installed this directly inside $HOME, as in `~/nixos/`, once installed simply running

```sh
rebuild
```

will suffice.
