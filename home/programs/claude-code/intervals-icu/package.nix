{
  lib,
  fetchFromGitHub,
  runCommand,
  python3,
  writeShellApplication,
}:

let
  # Only what mcp_server.py imports; the rest of requirements.txt is for the
  # notebooks. All of it is in nixpkgs, so unlike ../cronometer this builds here.
  pythonEnv = python3.withPackages (
    ps: with ps; [
      mcp
      requests
      python-dotenv
      pydantic
      jsonschema
    ]
  );

  src = fetchFromGitHub {
    owner = "rbrands";
    repo = "intervals-icu-sync";
    rev = "a7a74e6d4209d136025f4646c333dc93060f4f1e";
    hash = "sha256-8bR5LAEnINaaA3G6/IXuiOkTXfgbRNfQDHGDFDesC90=";
  };

  # The repo writes its data directories next to `__file__`, which is
  # read-only in the store. Most scripts already honour INTERVALS_RAW_DIR /
  # INTERVALS_PROCESSED_DIR; these are the three assignments that missed it,
  # plus INTERVALS_PLANS_DIR.
  patched = runCommand "intervals-icu-sync-src" { inherit src; } ''
    cp -r "$src" "$out"
    chmod -R u+w "$out"

    substituteInPlace "$out/scripts/mcp_server.py" \
      --replace-fail \
        'PROCESSED_DIR = _ROOT / "data" / "processed"' \
        'PROCESSED_DIR = Path(os.environ.get("INTERVALS_PROCESSED_DIR", str(_ROOT / "data" / "processed")))' \
      --replace-fail \
        'PLANS_DIR = _ROOT / "data" / "plans"' \
        'PLANS_DIR = Path(os.environ.get("INTERVALS_PLANS_DIR", str(_ROOT / "data" / "plans")))'

    substituteInPlace "$out/scripts/prepare_week_for_coach.py" \
      --replace-fail \
        'PROCESSED_DIR = _ROOT / "data" / "processed"' \
        'PROCESSED_DIR = Path(os.environ.get("INTERVALS_PROCESSED_DIR", str(_ROOT / "data" / "processed")))'
  '';
in

writeShellApplication {
  name = "intervals-icu-mcp";

  runtimeInputs = [ pythonEnv ];

  text = ''
    data_dir="''${XDG_STATE_HOME:-$HOME/.local/state}/intervals-icu-sync"
    export INTERVALS_RAW_DIR="$data_dir/raw"
    export INTERVALS_PROCESSED_DIR="$data_dir/processed"
    export INTERVALS_PLANS_DIR="$data_dir/plans"
    mkdir -p "$INTERVALS_RAW_DIR" "$INTERVALS_PROCESSED_DIR" "$INTERVALS_PLANS_DIR"

    exec python3 ${patched}/scripts/mcp_server.py "$@"
  '';

  meta = {
    description = "intervals.icu MCP server: training data, week plans, and calendar upload";
    homepage = "https://github.com/rbrands/intervals-icu-sync";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
    mainProgram = "intervals-icu-mcp";
  };
}
