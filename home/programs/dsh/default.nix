{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.apps.dsh;

  # Kept in step with ../claude-code/cronometer: the same pinned PyPI server,
  # run through uvx against nixpkgs' Python so uv never downloads its own.
  cronometer-mcp-version = "0.2.1";

  settingsFormat = pkgs.formats.yaml { };

  # $DSH_HOME/settings.yaml is mutable state the web UI owns, so this is a
  # merge rather than a copy: `select(fileIndex == 0) * select(fileIndex == 1)`
  # deep-merges the declared file over the live one, so a key nobody declared
  # here (ui-onboarding.welcomeNoticeVersion, anything set from a settings page)
  # survives every rebuild while declared keys are restored.
  dshHome =
    if config.programs.dsh.home != null then
      config.programs.dsh.home
    else
      "${config.home.homeDirectory}/.dsh";

  settingsFile = settingsFormat.generate "dsh-settings.yaml" cfg.settings;

  # Built from ../claude-code's scripts rather than relying on that module
  # having put them on PATH. Same name, same inputs, same text, so Nix resolves
  # these to the very store paths apps.claude-code already builds -- the coach
  # skill keeps working even if claude-code is switched off.
  weather = pkgs.writeShellApplication {
    name = "weather";
    runtimeInputs = with pkgs; [
      curl
      jq
      coreutils
      util-linux
    ];
    text = builtins.readFile ./../claude-code/weather/weather.sh;
  };

  intervals-icu = pkgs.writeShellApplication {
    name = "intervals-icu";
    runtimeInputs = with pkgs; [
      curl
      jq
      coreutils
    ];
    text = builtins.readFile ./../claude-code/intervals-icu.sh;
  };

  # Shared with ../claude-code/intervals-icu, the same way the two shell
  # wrappers above resolve to one store path: same file, same arguments, so
  # both modules land on the same derivation.
  intervals-icu-mcp = pkgs.callPackage ./../claude-code/intervals-icu/package.nix { };

  # Skills are plain SKILL.md directories, so the whole tree goes to the store
  # and dsh scans it read-only. dsh's own command registry is programmatic
  # (ctx.commands.register, from a plugin) and has no markdown loader, so the
  # claude-code `/coach` command ports to a skill rather than a command.
  #
  # Rendered from ../claude-code/coach rather than held as a second copy of the
  # same document: the two hand-maintained files had drifted 41 lines apart by
  # 2 Sep 2026, and this harness was the one missing the Cronometer write
  # prohibition it is the only one unable to enforce. Same import as
  # ../claude-code's, so both land on one derivation per output.
  skills = (import ./../claude-code/coach { inherit pkgs; }).skills;

  # The DeepSeek credit balance in the TUI status line -- `bal:$4.65 (2m)`,
  # and nothing else. Tokens, cache hit rate and context occupancy are already
  # rendered by the TUI from its own dsh-token-meter (see the statusBar
  # settings below), so the only real gap is `GET /user/balance`: an HTTP call
  # to the account, which nothing in the harness makes. Local source rather
  # than a fetched bundle because it does not exist upstream.
  dsh-usage = pkgs.callPackage ./usage.nix { inherit (pkgs) dsh; };

  # dsh-TUI 0.10.0-beta.1 instead of pkgs.dsh.bundles.tui (0.9.3), which cannot
  # boot against dsh-workspace 0.1.2-alpha.2. See ./tui.nix for the full story;
  # it is a temporary bridge, not a preference for the beta.
  dsh-tui = pkgs.dsh.callPackage ./tui.nix { };

  # Upstream's dshBundleCheckHook polls the web profile's endpoint with a bare
  # `curl` off PATH, and curl never arrives there: it is listed in the hook's
  # propagatedNativeBuildInputs, which for a multi-output package resolves to
  # the *dev* output -- `bin/curl-config`, no `bin/curl`. So the nix-web check
  # dies on "curl: command not found", waits out its 60s timeout and fails the
  # build even though the server booted fine (its log carries the `dsh web:
  # http://127.0.0.1:...` line the hook was waiting for).
  #
  # Substituting the store path into the script rather than fixing the
  # propagation: pointing the input at `lib.getBin pkgs.curl` does put a real
  # `bin/curl` in the hook's propagated set, but it still does not land on PATH
  # for the installCheck phase, and an absolute path does not care either way.
  dsh-check-hook =
    pkgs.makeSetupHook
      {
        name = "dsh-bundle-check-hook";
        propagatedNativeBuildInputs = with pkgs; [
          coreutils
          util-linux
        ];
      }
      (
        pkgs.runCommand "dsh-bundle-check-hook.sh" { } ''
          substitute ${pkgs.dsh.dshBundleCheckHook}/nix-support/setup-hook "$out" \
            --replace-fail 'curl --fail' '${lib.getExe' pkgs.curl "curl"} --fail'
        ''
      );

  # dsh itself, rebuilt against the hook above.
  #
  # `pkgs.dsh.overrideScope` does NOT work here, which is why this is shaped the
  # way it is. `withProfiles` composes as `dsh.override { profiles = ...; }`
  # against package.nix's own `dsh` argument -- the self-reference -- so the
  # composition always re-derives from whatever that argument points at, and a
  # scope-level override of a scope-local package never reaches it. Overriding
  # `dsh` to the fixed package alongside the hook ties that knot: the recursion
  # now lands on this package, so every `withProfiles`/`override` the module
  # layers on top keeps the working hook.
  dsh-fixed =
    let
      self = pkgs.dsh.dsh.override {
        dsh = self;
        dshBundleCheckHook = dsh-check-hook;
      };
    in
    self;

  # The declarative seam, now owned by deepseek-harness.nix. A profile composes
  # as: base layer, then the profile's bundles in list order, then this string
  # as the profile's cordis.patch.yml. Nothing is passed at launch any more --
  # the module materializes $DSH_HOME/profiles/nix-<name> from the store and
  # re-syncs it on every activation and every `dsh` run (mode = "managed").
  #
  # This has to be a *profile* patch rather than programs.dsh.patch: the
  # home-level option is typed `listOf attrs` and renders through
  # lib.generators.toYAML, which would quote the `!!js` tags below into inert
  # strings. The profile option also accepts `lines`, and renderPatch passes a
  # string through verbatim, so the tags survive.
  #
  # Two shapes are in play, both verified against --dump-config: a bare `id:`
  # row patches the entry that already exists under that id, and an `insert:`
  # list adds new ones. A patch REPLACES the targeted row's whole `config`, so
  # any row touched here restates every key it means to keep.
  cordisPatch = ''
    # Generated by home/programs/dsh/default.nix -- do not edit in place.

    # The skills system ships disabled in the web profile. tool-skill is the
    # model-facing loader; without it the catalogue is never readable. The tui
    # bundle enables both itself, but this layer applies after it, so stating
    # them here keeps all three profiles identical.
    - id: skill-filesystem
      disabled: false
      config:
        customSkillDirs:
          - ${skills}
    - id: tool-skill
      disabled: false

    # The AGENTS.md/CLAUDE.md workspace loader. Enabled in dsh-base, but the
    # tui bundle turns it off (dsh-tui/cordis.patch.yml:56), so the TUI would
    # otherwise see no project instruction files at all while headless does.
    # It walks the ancestor chain upward from the session workspace rather than
    # reading only the root, so per-project files are picked up the way
    # claude-code does it. maxBytes is restated because a patch replaces the
    # targeted row's whole config.
    - id: agent-instructions
      disabled: false
      config:
        maxBytes: 65536

    # Claude as a model route. pi-ai (the multi-provider layer under
    # dsh-llm-pi-ai) bundles @anthropic-ai/sdk and ships anthropic in its
    # installed catalog, so the route needs no baseURL, protocol or model list
    # -- only where to find the credential. The monorepo does carry a
    # subagent-claude-code package, but dsh-base does not depend on it in
    # 0.1.2-alpha.2, so it reaches none of these profiles and this is still
    # what "Claude in dsh" means today.
    #
    # Qwen3.8-27B through Qwen Cloud, which is a front end over DashScope
    # International -- hence the aliyuncs endpoint. Deliberately NOT the
    # openrouter route: pi-ai ships openrouter, but the compat gate withholds
    # openRouterRouting, so nothing can pin which of its eleven upstreams
    # serves a request. That means an unknown quantization and an unknown
    # context ceiling per call, which is the wrong footing for judging whether
    # this model is worth keeping. Official costs ~18% more ($0.50/$3.00
    # against $0.35/$2.75) and answers with the reference weights at 1M.
    #
    # pi-ai 0.84.2 ships no `qwen-cloud` provider, and its nearest route
    # (qwen-token-plan) points somewhere else entirely
    # (token-plan.ap-southeast-1.maas.aliyuncs.com), so this route declares the
    # whole provider: endpoint and wire protocol included. Being off-catalog is
    # the upside -- per dsh-llm-pi-ai's discovery.d.ts, "fetch available
    # models" only interrogates a route the catalog does NOT ship, so this one
    # can actually be probed from the web UI, while an openrouter route would
    # answer from its bundled Qwen3.6-era list.
    #
    # Two model fields are load-bearing because a hand-declared model defaults
    # to neither: `input` (the route default is [text], which would leave the
    # vision encoder unreachable) and `reasoningEfforts` (absent means "does
    # not reason", and thinking mode is the reason to run this model). "off" is
    # quoted because a bare `off` is a YAML 1.1 boolean.
    #
    # maxTokensField and supportsUsageInStreaming are stated rather than left
    # to pi-ai, which for an endpoint it does not recognize answers as though
    # it were OpenAI itself -- wrong for most OpenAI-compatible gateways.
    #
    # Qwen Cloud's built-in tools (code_interpreter, web_search, ...) are
    # Responses-API-only server-side tools and are not reachable over
    # openai-completions. That costs nothing: dsh's own web_search runs through
    # the `web` service against DEEPSEEK_API_KEY, independent of whichever
    # model is serving chat, so it keeps working unchanged under this route.
    #
    # The key is region-bound and the name does not say so. Model Studio keys
    # only authenticate against the region that issued them (a mismatch is 401
    # invalid_api_key), and catalogs differ per region -- verified 2026-08-28,
    # Frankfurt serves qwen3.8-max but NOT this model, Singapore serves both.
    # So `dashscope-api-key` is specifically the SINGAPORE key, and adding a
    # second region later means a second secret rather than replacing this one.
    #
    # baseURL is the shared Singapore endpoint rather than the workspace-scoped
    # ws-<id>.ap-southeast-1.maas.aliyuncs.com form. Both serve this model.
    # Alibaba documents the workspace form as the newer path with better
    # stability and is steering away from the shared domains, so this may want
    # revisiting; it is a one-line change, and the only cost is putting the
    # workspace id into a world-readable /nix/store file.
    #
    # The UI writes provider settings into $DSH_HOME/settings.yaml, which
    # resolves ON TOP of this, so adding routes by hand there still works. A
    # missing key surfaces per request as MISSING_CREDENTIAL rather than
    # failing the boot.
    - id: llm-pi-ai
      config:
        providers:
          anthropic:
            apiKeyEnv: ANTHROPIC_API_KEY
          qwen-cloud:
            apiKeyEnv: DASHSCOPE_API_KEY
            displayName: Qwen Cloud
            api: openai-completions
            baseURL: https://dashscope-intl.aliyuncs.com/compatible-mode/v1
            models:
              - id: qwen3.8-27b
                name: Qwen3.8 27B
                contextWindow: 1000000
                maxTokens: 131072
                input:
                  - text
                  - image
                reasoningEfforts:
                  "off": null
                  low: low
                  medium: medium
                  high: high
                compat:
                  thinkingFormat: qwen
                  maxTokensField: max_tokens
                  supportsUsageInStreaming: true
                  # pi-ai sends the system prompt under the `developer` role to
                  # any model that declares reasoning, which this one does.
                  # DashScope answers 400: "developer is not one of ['system',
                  # 'assistant', 'user', 'tool', 'function']". false keeps
                  # `system`. Probed 2026-08-28: developer is the ONLY field of
                  # the OpenAI-shaped set this endpoint rejects -- store,
                  # reasoning_effort, max_completion_tokens and strict tools
                  # are all accepted.
                  supportsDeveloperRole: false

    - insert:
        # Cronometer, mirroring ../claude-code/cronometer. Credentials arrive as
        # process env from the session (see programs.bash.initExtra below)
        # rather than being written here: this file is world-readable in
        # /nix/store.
        - id: mcp-cronometer
          name: '@deepseek-ai/dsh-mcp-client'
          config:
            serverName: cronometer
            transport: stdio
            command: ${lib.getExe' pkgs.uv "uvx"}
            args:
              - '--python'
              - '${pkgs.python314}/bin/python3'
              - 'cronometer-api-mcp==${cronometer-mcp-version}'
            env:
              # `?? '''` is load-bearing: env is typed { [key]: string }, and a
              # bare process.env ref for an unset variable resolves to undefined,
              # which fails validation and takes the whole boot down rather than
              # just this server. An empty value degrades to an auth failure on
              # the server instead, which failOnStartupError (default false)
              # contains.
              CRONOMETER_USERNAME: !!js process.env.CRONOMETER_USERNAME ?? '''
              CRONOMETER_PASSWORD: !!js process.env.CRONOMETER_PASSWORD ?? '''
              CRONOMETER_ACCOUNT_TZ: Europe/Amsterdam
              UV_PYTHON_DOWNLOADS: never
  '';
in
{
  options.apps.dsh = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable DeepSeek Harness (dsh)";
    };

    settings = lib.mkOption {
      type = settingsFormat.type;
      default = { };
      example = lib.literalExpression ''
        {
          some-plugin = {
            command = "some-plugin-server";
            recallBudgetTokens = 1200;
          };
        }
      '';
      description = ''
        Declared `$DSH_HOME/settings.yaml` entries, keyed by the namespace each
        plugin registers. Merged into the existing file on activation: declared
        keys win, everything else the web UI wrote is left alone.

        This is the escape hatch for plugins that register their configuration
        through the settings service instead of a Cordis config schema -- those
        cannot be reached from the profile patch at all.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # Nothing declared here at the moment. graph-memory, which replaced noema as
    # the memory layer, configures through its Cordis schema (the `graph-memory`
    # row in its bundle patch) rather than the settings service, so it needs no
    # namespace here and no one-time setup in the web UI. The option stays
    # because the next plugin may well go the other way.

    programs.dsh = {
      enable = true;

      # Carries the dshBundleCheckHook curl fix through every composition the
      # module builds from it.
      package = dsh-fixed;

      # One profile per interaction face -- the face bundles are mutually
      # exclusive, so they cannot share a tree. Each materializes as
      # $DSH_HOME/profiles/nix-<name>.
      #
      # graph-memory rides on the two interactive faces only: its recall is
      # worth having wherever a conversation continues, but headless is one-shot
      # and would only pay to open the store. It replaces dsh-noema, which
      # cannot load at all under 0.1.2-alpha.2 -- noema imports
      # `settingsNamespace` from @deepseek-ai/dsh-settings and that export is
      # gone, so the plugin tree dies at boot. Its upstream is dormant (last
      # commit 2026-08-21, still declaring DSH 0.1.1-rc.1 as its tested target),
      # so this is a replacement rather than a wait.
      #
      # graph-memory was picked over the other packaged memory layers on one
      # hard constraint: mneme and memento inject `webServer`, so under the TUI
      # profile they never activate and the boot check fails on a pending entry.
      # graph-memory injects only base services (tools, llm, systemPrompt,
      # agentLoop, agents, agentPresets, sessions, credentials), needs no
      # companion server process the way noema needed noema-mcp, and keeps its
      # store in $DSH_HOME/graph-memory/graph-memory.db. It is FTS5 keyword
      # recall out of the box; setting GRAPH_MEMORY_EMBEDDING_API_KEY (plus
      # _BASE_URL/_MODEL/_DIMENSIONS) in the dsh environment turns on semantic
      # vector recall.
      #
      # The old store is left untouched at ~/.agent-memory. Its 11 live entries
      # are exported to $DSH_HOME/graph-memory/noema-export.md; feed them back
      # with the `gm_record` tool when convenient.
      profiles = {
        # dsh-usage rides on the TUI alone: the status line is the whole point
        # of it, and `tuiStatus` exists nowhere else. It holds no state, so
        # mounting it elsewhere would be harmless -- just inert.
        #
        # Last in the list so its `insert` lands after the tui bundle's rows.
        # The row also injects `tuiStatus`, which is what actually guarantees
        # ordering -- list position alone does not, since rows load
        # concurrently, and a row that activates before the service exists has
        # its status writes silently rejected for the whole session.
        #
        # Defaults are unconfigured on purpose -- they are already the choices
        # this host would make (poll every 5 min, credential from
        # $DEEPSEEK_API_KEY, which the `dsh` wrapper below exports).
        # ./usage/README.md lists the whole config surface; anything worth
        # changing goes in a `- id: dsh-usage` row in this profile's patch,
        # which applies after the bundle's own layer.
        tui = {
          bundles = [
            dsh-tui
            pkgs.dsh.bundles.graph-memory
            dsh-usage
          ];
          patch = cordisPatch;
        };
        web = {
          bundles = [
            pkgs.dsh.bundles.web-app
            pkgs.dsh.bundles.graph-memory
          ];
          patch = cordisPatch;
        };
        headless = {
          bundles = [ pkgs.dsh.bundles.headless ];
          patch = cordisPatch;
        };
      };

      # Bare `dsh` boots the TUI. Anything else is `dsh --profile nix-web` etc;
      # the `dsh web` sugar is gone with the old wrapper, since it only ever
      # existed to work around --patch's placement rules.
      defaultProfile = config.programs.dsh.profiles.tui.materializedName;
    };

    # The web face as a systemd user unit instead of a foreground `dsh
    # --profile nix-web`. This is the one path with a real secret story:
    # EnvironmentFile= is read by systemd when the unit starts, so the keys
    # reach dsh without a shell profile, without the store, and without landing
    # in every other process's environment the way the bash exports below do.
    # The TUI cannot use it -- it runs in your terminal, not under systemd --
    # so that face still depends on programs.bash.initExtra.
    #
    # Everything else is upstream's default and already matches this config:
    # `profiles` inherits programs.dsh.profiles, `profile` is "nix-web" (the web
    # profile's materializedName), listenAddress/port are 127.0.0.1:3080, and
    # dataDir resolves to the same $DSH_HOME -- so settings.yaml, the profile
    # trees and the graph-memory store are shared with the TUI rather than
    # forked.
    #
    # autoStart is off: the web face is not in normal use, and an always-on unit
    # is not free. Measured idle cost was ~275 MB RSS across three processes --
    # node, plus a uvx/python mcp-cronometer pair it spawns at boot and holds
    # open forever whether or not anything queries it -- and it binds 3080
    # unauthenticated from login onward, which is a standing agent endpoint with
    # a live API key rather than a foreground process that can be Ctrl-C'd.
    # `systemctl --user start dsh-web` when the web UI is actually wanted.
    #
    # --no-open because the unit inherits the session manager's environment
    # (BROWSER, WAYLAND_DISPLAY are imported there), so every start -- including
    # each Restart=on-failure -- otherwise opens a real Firefox tab.
    #
    # Starting it while `dsh --profile nix-web` runs in the foreground is the
    # EADDRINUSE case; stop one or the other.
    services.dsh = {
      enable = true;
      autoStart = false;
      extraArguments = [ "--no-open" ];
      environmentFile = "/run/secrets/rendered/dsh-env";
    };

    # dsh has no file-based credential path: `!!js` runs in an ESM bundle with
    # no `require`, and dsh-mcp-client has no envFile option, so both the
    # provider keys and the Cronometer pair have to be real environment
    # variables before dsh starts. sops decrypts to /run/secrets at activation;
    # this reads them at shell start.
    #
    # This is the TUI/headless half of the story -- the dsh-web unit above gets
    # the same values through sops.templates."dsh-env" instead. Both derive from
    # the same sops.secrets entries, so there is one source of truth even though
    # there are two delivery paths.
    #
    # A wrapper function rather than exports at shell start: `local -x` scopes
    # each value to this function and its children, so the keys exist for the
    # dsh process tree and nowhere else. Exporting at login instead put a live
    # API key and the Cronometer password into every shell and every child of
    # one -- build tools, npm scripts, anything whose environment ends up in a
    # log, a crash report or a screen share. That is exposure surface, not a
    # privilege boundary: /run/secrets/* is 0400 and owned by this user, so
    # anything running as the user could always read the files directly.
    #
    # `command dsh` bypasses the function, so this covers every face -- bare
    # `dsh` for the TUI and `dsh --profile nix-headless` are the same binary.
    # As with the exports it replaces, this reaches interactive bash only.
    #
    # An already-set value wins, so a var exported by hand for a one-off is not
    # clobbered. ANTHROPIC_API_KEY has no sops.secrets entry yet -- declaring
    # one that does not exist fails activation. The readability guard keeps it
    # unset rather than empty until the secret is added, at which point the
    # anthropic route above starts resolving.
    programs.bash.initExtra = lib.mkAfter ''
      dsh() {
        local pair var file
        for pair in \
          "DEEPSEEK_API_KEY=/run/secrets/deepseek-api-key" \
          "DASHSCOPE_API_KEY=/run/secrets/dashscope-api-key" \
          "CRONOMETER_USERNAME=/run/secrets/cronometer-email" \
          "CRONOMETER_PASSWORD=/run/secrets/cronometer-password" \
          "ANTHROPIC_API_KEY=/run/secrets/anthropic-api-key"
        do
          var=''${pair%%=*}
          file=''${pair#*=}
          if [ -z "''${!var:-}" ] && [ -r "$file" ]; then
            local -x "''${var?}"
            printf -v "$var" '%s' "$(< "$file")"
          fi
        done
        command dsh "$@"
      }
    '';

    # Restores the declared settings on every activation without taking the file
    # over. Runs whether or not dsh has started before: an absent settings.yaml
    # is installed outright, an existing one is merged into.
    home.activation.dshSettings = lib.mkIf (cfg.settings != { }) (
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        dsh_settings=${lib.escapeShellArg "${dshHome}/settings.yaml"}
        $DRY_RUN_CMD mkdir -p "$(dirname "$dsh_settings")"
        if [ -e "$dsh_settings" ]; then
          $DRY_RUN_CMD ${lib.getExe pkgs.yq-go} eval-all --inplace \
            'select(fileIndex == 0) * select(fileIndex == 1)' \
            "$dsh_settings" ${settingsFile}
        else
          $DRY_RUN_CMD install -m 0644 ${settingsFile} "$dsh_settings"
        fi
      ''
    );

    # The coach skill drives weather/intervals-icu through the bash tool, which
    # inherits the session PATH -- the old wrapper's runtimeInputs is what this
    # replaces.
    #
    # pkgs.dsh.noema-mcp is gone with noema itself: graph-memory talks to its
    # own SQLite store in-process, so there is no companion server binary to put
    # on PATH and nothing to point a settings page at.
    home.packages = [
      weather
      intervals-icu
    ];
  };
}
