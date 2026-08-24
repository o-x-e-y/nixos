{
  lib,
  buildNpmPackage,
  nodejs_24,
  makeWrapper,
  bashInteractive,
  ripgrep,
  git,
}:
# DeepSeek Harness is only distributed as a set of pre-bundled npm packages; the
# GitHub checkout builds through a pnpm 11 workspace, tsdown, a Vite frontend and
# a Rust landlock sandbox that is not published at all, so there is nothing to
# gain from building from source. npm it is.
#
# The published tarball carries no lockfile, so `src` here is not an upstream
# checkout but a two-file shim: package.json names exactly one pinned dependency
# and package-lock.json pins the ~500-package closure it resolves to. Bumping the
# version means editing package.json, regenerating the lock, and refreshing
# npmDepsHash.
buildNpmPackage (finalAttrs: {
  pname = "dsh";
  version = "0.1.1-rc.2";

  src = ./.;

  npmDepsHash = "sha256-0VGJXOr7zBYPmc7rFv8+Jm7P5xS/mNsDjL+hhry6E6Y=";

  nodejs = nodejs_24;

  nativeBuildInputs = [ makeWrapper ];

  # The shim has no build script of its own; every @deepseek-ai package on npm
  # ships already bundled.
  dontNpmBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib
    cp -r node_modules $out/lib/

    # --expose-internals is not optional here: cordis-plugin-hmr is part of the
    # default profile and its constructor hard-fails without it on a Nix-built
    # node, so every profile boot dies before serving. Upstream lists arm64,
    # musl and Nix-built node as the affected set. It must precede the script
    # path, and NODE_OPTIONS will not carry it.
    #
    # Nothing in this config puts node on PATH, so the wrapper supplies the whole
    # runtime environment. bash is the one that matters on NixOS: dsh-bash-sandbox
    # spawns a bare ['bash', '-c', cmd] argv and lets PATH resolve it, so the bash
    # tool is dead without it. (The '/bin/bash' default upstream warns about lives
    # in dsh-terminal-bash, which the shipped profiles do not load — worth knowing
    # if a future profile pulls it in, since that one needs a shellPath override
    # instead.) ripgrep backs dsh-tool-fs-search, git backs the fs tools.
    makeWrapper ${lib.getExe nodejs_24} $out/bin/dsh \
      --add-flags "--expose-internals" \
      --add-flags $out/lib/node_modules/@deepseek-ai/dsh/lib/bin.js \
      --prefix PATH : ${
        lib.makeBinPath [
          bashInteractive
          ripgrep
          git
        ]
      }

    runHook postInstall
  '';

  meta = {
    description = "DeepSeek Harness: an agent harness where everything is a plugin";
    homepage = "https://github.com/deepseek-ai/deepseek-harness";
    license = lib.licenses.mit;
    mainProgram = "dsh";
    platforms = lib.platforms.linux;
  };
})
