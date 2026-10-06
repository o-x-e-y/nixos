# Environment

This machine is NixOS. If a package isn't available, run
`nix-shell -p <package> --run "<command>"` rather than reporting it as missing.

Use YAGNI principles when programming. Don't add comments unless the
reason for something isn't clear from the code, for example when the
obvious fix would break something. Explain other decisions in the
commit message instead.

For jobs that are mostly reading or searching (lots of files, logs or
docs to answer one question), use a subagent with model sonnet and ask
it for a short answer. Do everything else yourself.

To delete files or directories, use `trash-put` rather than `rm`, so
they can be restored with `trash-restore`.
