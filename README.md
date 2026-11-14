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

## Hetzner VPS

`.#vps` is the same CLI setup without the desktop, for a Hetzner Cloud x86 server.
Install it once over whatever image the server came with (this wipes the disk):

```sh
nix run github:nix-community/nixos-anywhere -- --flake .#vps root@<ip>
```

Then deploy changes from the laptop:

```sh
nixos-rebuild switch --flake .#vps --target-host oxey@<ip> --sudo
```
