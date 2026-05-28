{ pkgs, lib, ... }:
let
  generateServersDat = pkgs.writeScript "generate-servers-dat" ''
    #!${pkgs.python3}/bin/python3
    import struct, os

    def tag_string(name, value):
        n, v = name.encode(), value.encode()
        return bytes([8]) + struct.pack('>H', len(n)) + n + struct.pack('>H', len(v)) + v

    def tag_byte(name, value):
        n = name.encode()
        return bytes([1]) + struct.pack('>H', len(n)) + n + struct.pack('>b', value)

    def compound(s):
        return tag_string('ip', s['ip']) + tag_string('name', s['name']) + tag_byte('acceptTextures', 0) + b'\x00'

    servers = [
        {'ip': open('/run/secrets/grahp-city').read().strip(), 'name': 'Graph AKL City'},
        {'ip': open('/run/secrets/grahp-survival').read().strip(), 'name': 'Grahp AKL Survival'},
    ]

    payload = b'''.join(compound(s) for s in servers)
    servers_name = b'servers'
    nbt = (
        b'\x0a\x00\x00'
        + b'\x09' + struct.pack('>H', len(servers_name)) + servers_name
        + b'\x0a' + struct.pack('>i', len(servers))
        + payload
        + b'\x00'
    )

    out = os.path.expanduser('~/.minecraft/servers.dat')
    os.makedirs(os.path.dirname(out), exist_ok=True)
    with open(out, 'wb') as f:
        f.write(nbt)
  '';
in
{
  home.packages = [ pkgs.prismlauncher ];

  home.activation.minecraftServers = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD ${generateServersDat}
  '';
}
