{
  lib,
  fetchFromGitHub,
  runCommand,
  python3,
  writeShellApplication,
}:

let
  # requirements.txt also lists jupyter/pandas/matplotlib/pre-commit/nbstripout,
  # but those belong to the notebook and analysis scripts, not the MCP server:
  # mcp_server.py and everything it imports need only these five. All are in
  # nixpkgs at versions the pins accept (mcp 1.27.1 against `mcp[cli]>=1,<2`,
  # pydantic 2.13.4 against `>=2,<3`, jsonschema 4.26.0 against `>=4.23,<5`), so
  # unlike ../cronometer this one builds here instead of running through uvx.
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

  # The repo is written to be run from a checkout: it derives its data
  # directories from `__file__` and writes into them. `save_week_plan` writes
  # data/plans/week_plan.json and `upload_week_plan` reads it back, so from a
  # /nix/store path the whole write half fails on a read-only filesystem --
  # which is the half worth having over the existing intervals-icu.sh reader.
  #
  # Upstream already solved this for most scripts: get_activities, get_metrics,
  # get_training_plan, fueling_analysis, analyze_week and both prepare_*_for_coach
  # honour INTERVALS_RAW_DIR / INTERVALS_PROCESSED_DIR. Only three assignments
  # were missed, so this extends that convention rather than inventing one.
  # INTERVALS_PLANS_DIR is the only new name.
  #
  # `os` and `Path` are already imported in both files, and _run_script passes a
  # copy of os.environ to every subprocess, so the overrides reach the scripts
  # the server shells out to.
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

# stdio only. The repo also ships an SSE/webservice mode behind OAuth for Azure
# hosting; that is a different deployment shape and nothing here wants a second
# listening socket.
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
