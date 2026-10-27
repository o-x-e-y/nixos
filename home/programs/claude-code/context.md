# Environment

This machine is NixOS. If a package isn't available, run
`nix-shell -p <package> --run "<command>"` rather than reporting it as missing.

Use YAGNI principles when programming. Don't add comments unless the
reason for something isn't clear from the code, for example when the
obvious fix would break something. Explain other decisions in the
commit message instead.

Before saying something works, run whatever proves it. A subagent's
report isn't proof: check the diff. A regression test should fail
without the fix. When debugging, find the cause before changing code,
and after three fixes that didn't work, stop and rethink the approach.

For jobs that are mostly reading or searching (lots of files, logs or
docs to answer one question), use a subagent with model sonnet and ask
it for a short answer. Do everything else yourself. Brief a subagent
as if it knows nothing: give it the goal, the context it needs, what
it shouldn't touch and the shape of the answer you want back.

To delete files or directories, use `trash-put` rather than `rm`, so
they can be restored with `trash-restore`.
