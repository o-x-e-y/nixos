{
  lib,
  stdenvNoCC,
  nodejs-slim,
  dsh,
}:

# The usage meter as a dsh bundle. `pkgs.dsh.buildDshBundle` is not used here:
# it wraps buildNpmPackage, whose npmConfigHook wants a dependency closure to
# install, and this plugin has none -- plain ESM, no build step. So the bundle
# contract is satisfied directly. Only three things are load-bearing, and the
# last two are checked by dsh at composition time:
#
#   1. $out/lib/node_modules/<name>/ holding a package.json that declares
#      `dsh.bundle.patch` -- resolve-dsh-bundles.mjs dies with "no package
#      declares dsh.bundle.patch" without it.
#   2. $out/nix-support/dsh-bundles.json, which pkgs/dsh/profiles.nix reads to
#      order the Cordis patch layers. Generated with upstream's own resolver
#      rather than written by hand, so it cannot drift from the format the
#      reader verifies.
#   3. The passthru protocol pkgs/dsh/composition.nix validates.
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "dsh-usage";
  version = "0.1.0";

  # An explicit fileset rather than ./usage, so an editor swapfile or a stray
  # node_modules cannot change the store hash.
  src = lib.fileset.toSource {
    root = ./usage;
    fileset = lib.fileset.unions [
      ./usage/src
      ./usage/tests
      ./usage/package.json
      ./usage/cordis.patch.yml
      ./usage/README.md
    ];
  };

  nativeBuildInputs = [ nodejs-slim ];

  dontConfigure = true;
  dontBuild = true;

  # The suite is pure and dependency-free, so it runs in the sandbox. This is
  # deliberate: a rebuild that would ship a broken status line fails here
  # instead of at the next `dsh` launch.
  doCheck = true;
  checkPhase = ''
    runHook preCheck
    node --test "tests/*.test.js"
    runHook postCheck
  '';

  installPhase = ''
    runHook preInstall

    target="$out/lib/node_modules/@oxey/dsh-usage"
    mkdir -p "$target"
    cp -r src package.json cordis.patch.yml README.md "$target/"

    mkdir -p "$out/nix-support"
    ${lib.getExe dsh.buildDshBundle.dshBundleResolver} manifest \
      "$out/nix-support/dsh-bundles.json" \
      "$out/lib/node_modules"

    runHook postInstall
  '';

  passthru = {
    dshBundle = true;
    dshBundleHelper = "buildDshBundle";
    runtimeDeps = [ ];
  };

  meta = {
    description = "DeepSeek credit balance in the dsh TUI status line";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
  };
})
