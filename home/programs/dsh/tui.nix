{
  lib,
  fetchFromGitHub,
  fetchPnpmDeps,
  fetchurl,
  buildDshBundle,
  dsh-kernel,
  pnpmConfigHook,
  pnpm_11,
}:

let
  # See the installPhase note below. Straight off npm because neither the
  # kernel nor the composed dsh ships this package, so there is no store path
  # to copy the matching build out of.
  codeRuntimeWorkerThread = fetchurl {
    url = "https://registry.npmjs.org/@deepseek-ai/dsh-code-runtime-worker-thread/-/dsh-code-runtime-worker-thread-0.1.2-alpha.2.tgz";
    hash = "sha256-hX1uu/aWhrLombNO7fCuZVlC0nZ6F0dn9Y8pGHUlY5c=";
  };
in

# dsh-TUI 0.10.0-beta.2, replacing the 0.9.3 that deepseek-harness.nix pins.
#
# This exists because the pinned pair does not boot. dsh-workspace 0.1.2-alpha.2
# dropped `resolveSessionPreset` from @deepseek-ai/dsh-agent-presets (replaced
# by `agentPresetProjectionDefinition`), and dsh-TUI 0.9.3 still imports it from
# src/dsh-adapter/presets.ts -- so the plugin loader dies at boot and
# dshBundleCheckHook fails the whole build on `dsh --profile nix-tui --help`.
# 0.9.3 says as much in its own manifest: its peer range for that package is
# `^0.1.0-rc.6 || ^0.1.1-rc.1`, which 0.1.2-alpha.2 does not satisfy. The
# harness bumped the workspace to 0.1.2 on 2026-08-30 without moving the TUI off
# 0.9.3 (last bumped 2026-08-27), which is also why its cachix has no build for
# this revision.
#
# 0.10.0-beta.1 was the first release that widens the range to include
# `^0.1.2-alpha.2` and drops the removed import; beta.2 additionally fixes a
# startup crash (#662: Divider width measurement failing to converge, which
# tripped a React #185 nested-update loop). It is a beta, and it is here only as
# a bridge: delete this file and go back to `pkgs.dsh.bundles.tui` as soon as
# deepseek-harness.nix pins a TUI that supports 0.1.2.
#
# Otherwise a faithful copy of the upstream pkgs/bundles/tui/package.nix, with
# the three submodule pins re-read from the tag and one installPhase change:
# 0.10.0-beta.1 removed the top-level `skills/` tree and ships `presets/` in its
# place (see its package.json `files`), so copying `skills` would fail. beta.2
# leaves all three submodule revisions and the pnpm dependency tree untouched,
# so those hashes carry over from beta.1 unchanged.
buildDshBundle (finalAttrs: {
  pname = "dsh-tui";
  version = "0.10.0-beta.2";

  src = fetchFromGitHub {
    owner = "ccch1mneyyy";
    repo = "dsh-TUI";
    tag = "v${finalAttrs.version}";
    hash = "sha256-K9mDyi5jfJKKMNDrzw/Dj2mB1xGe+IyCu73O92r/9Xk=";
  };

  postPatch = ''
    rm -rf vendor/dsh-std dsh-ecosystem-spec dsh-auth
    mkdir -p vendor/dsh-std dsh-ecosystem-spec dsh-auth
    cp -r ${finalAttrs.passthru.dshStd}/. vendor/dsh-std/
    cp -r ${finalAttrs.passthru.dshEcosystemSpec}/. dsh-ecosystem-spec/
    cp -r ${finalAttrs.passthru.dshAuth}/. dsh-auth/
    chmod -R u+w vendor/dsh-std dsh-ecosystem-spec dsh-auth

    # fetchFromGitHub provides a tarball without a Git index, but verify:i18n
    # only needs the source file list for its static scan.
    substituteInPlace scripts/verify-i18n.ts \
      --replace-fail \
        "execSync('git ls-files src scripts', { encoding: 'utf8' })" \
        "execSync('find src scripts -type f -print', { encoding: 'utf8' })"
  '';

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    pnpm = pnpm_11;
    fetcherVersion = 4;
    postPatch = finalAttrs.postPatch;
    prePnpmInstall = ''
      pnpm --dir vendor/dsh-std install \
        --ignore-scripts \
        --frozen-lockfile \
        --registry="$NIX_NPM_REGISTRY"
    '';
    hash = "sha256-Q33gyQ9KF1RJlnlvhLMn+FyMnKTnrNJi8mRzJJU2s/E=";
  };

  nativeBuildInputs = [ pnpm_11 ];
  disallowedReferences = [ pnpm_11 ];
  linkKernelNodeModules = dsh-kernel;
  # dsh-tui compiles against React 19, while dsh-kernel carries React 18.
  linkKernelNodeModulesKeep = [
    "ansi-styles"
    "react"
  ];

  npmDeps = null;
  npmConfigHook = pnpmConfigHook;
  npmBuildScript = "build";

  installPhase = ''
    runHook preInstall

    appDir="$out/lib/node_modules/@deepseek-harness-tui/dsh-tui"
    mkdir -p "$appDir"

    cp -r package.json cordis.patch.yml cordis.yml dsh-ecosystem-spec presets lib "$appDir/"
    # Bundle-private deps such as auto-bind and dsh-working-activity are not in
    # the kernel; linkKernelNodeModules merges the kernel peers into this tree.
    cp -r node_modules "$appDir/node_modules"

    # Workspace links point into vendor/dsh-std, which is not installed.
    rm -rf "$appDir/node_modules/@dsh-std"
    mkdir -p "$appDir/node_modules/@dsh-std"
    cp -rL node_modules/@dsh-std/. "$appDir/node_modules/@dsh-std/"

    # dsh-auth is a workspace link in the source tarball and must be copied
    # into the final bundle instead of leaving a dangling link.
    rm -rf "$appDir/node_modules/@deepseek-harness-tui/dsh-auth"
    mkdir -p "$appDir/node_modules/@deepseek-harness-tui/dsh-auth"
    cp -rL node_modules/@deepseek-harness-tui/dsh-auth/. \
      "$appDir/node_modules/@deepseek-harness-tui/dsh-auth/"

    # dsh-TUI's committed pnpm-lock.yaml resolves
    # @deepseek-ai/dsh-code-runtime-worker-thread to 0.1.1-rc.2 (still true in
    # beta.2: an exact `specifier: 0.1.1-rc.2` at pnpm-lock.yaml:190), even
    # though its package.json range admits ^0.1.2-alpha.2. The kernel does not ship that
    # package, so linkKernelNodeModules cannot correct it the way it does for
    # every other harness dependency, and the bundle ends up as the one mixed
    # entry in an otherwise uniform 0.1.2-alpha.2 tree.
    #
    # That single package is what the TUI's own engine-version contract trips
    # on: contract.ts resolves each blessed package's manifest with
    # import.meta.resolve (so from inside this bundle, never from $DSH_HOME)
    # and LogoV2 renders "Mixed dsh engine versions detected (0.1.1-rc.2 /
    # 0.1.2-alpha.2)" on every launch. Its only runtime dependency is
    # @deepseek-ai/schemastery, which the tree already carries at 3.18.2, so
    # replacing the payload is safe.
    #
    # Overwriting inside .pnpm rather than the top-level link, so anything
    # resolving through the virtual store sees the new version too. The
    # directory name still says 0.1.1-rc.2; only its contents are read.
    worker=$(readlink -f "$appDir/node_modules/@deepseek-ai/dsh-code-runtime-worker-thread")
    chmod -R u+w "$worker"
    rm -rf "''${worker:?}"/*
    tar xzf ${codeRuntimeWorkerThread} -C "$worker" --strip-components=1

    runHook postInstall
  '';

  passthru = {
    dshStd = fetchFromGitHub {
      owner = "Yan-Zero";
      repo = "dsh-std";
      rev = "614dfa1ac168db79fcf4577cf0ebb34e2e3b944b";
      hash = "sha256-aJEykWAXEKTUsNte51+ZEhFAgLT6QNNplNZTNPhgb00=";
    };
    dshEcosystemSpec = fetchFromGitHub {
      owner = "T-Auto";
      repo = "dsh-ecosystem-spec";
      rev = "d28c267fe7fd775428ec2dccd65b0b7efd4dacee";
      hash = "sha256-hhp/UUMo2engw0SyrB0Gq6Xc6BUYgvEmYh0F4OBdZEw=";
    };
    dshAuth = fetchFromGitHub {
      owner = "ccch1mneyyy";
      repo = "dsh-auth";
      rev = "4e7cba3854e8874c8114bac2133aba3a7e1a65fe";
      hash = "sha256-H2h/yyg56pDMMnx3YvC5xxXdX4T80V2tz8A32vua2LU=";
    };
    inherit (finalAttrs) pnpmDeps;
    # Deliberately NOT `requiresTui`, which upstream's 0.9.3 does set. In
    # profiles.nix that flag means "this profile needs the TUI bundle added",
    # and the bundle it adds is pkgs.dsh.bundles.tui -- so declaring it here
    # pulls 0.9.3 in alongside this one and the resolver aborts with
    # "conflicting bundle metadata for @deepseek-harness-tui/dsh-tui".
    # This bundle *is* the TUI, and the profile lists it directly.
    requiresTty = true;
  };

  meta = {
    description = "Interactive terminal interface for dsh";
    homepage = "https://github.com/ccch1mneyyy/dsh-TUI";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
  };
})
