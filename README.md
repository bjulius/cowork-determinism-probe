# cowork-determinism-probe

A small test plugin that checks whether a Claude harness actually *runs* the controls a plugin can declare, not just accepts them. I built it to compare Claude Code with Cowork for a CPA friend who needs deterministic, auditable workflows.

"Loads" and "runs" are not the same thing. A control that is accepted but never executed is worse than no control, because you think you are protected.

## What's in the plugin

| Part | What it tests |
|---|---|
| `SessionStart` command hook | Does a hook run at all? It hands the model a random nonce the model cannot guess. |
| `PreToolUse` command hook | Can a hook enforce a control? It blocks any tool call whose input mentions `LOCKED`, whether by the Write tool or the shell. |
| `PostToolUse` command hook | Can a hook keep an audit trail? It appends one line per tool call to `probe-hook-log.txt`. |
| `reconcile-tb` skill + `reconcile.py` | Does a bundled script run, and is its output identical every time? It totals a small **synthetic** trial balance with exact decimal arithmetic and prints the SHA-256 of the output file. |
| `readonly-auditor` agent | Is a subagent's `tools:` allow-list enforced? |

`extras/readonly-auditor-examples.md` is a second agent whose frontmatter uses the `<example>` block style shown in Cowork's plugin-authoring guide. That frontmatter is invalid YAML. In my Claude Code test it loaded silently and dropped the tool allow-list; Cowork's uploader rejected it. It is kept out of the plugin on purpose - copy it into `determinism-probe/agents/` only if you want to reproduce that result.

## Run it

1. **Claude Code:** `claude --plugin-dir ./determinism-probe`
2. **Cowork:** Customize > Plugins > Add > Upload plugin, and pick `determinism-probe.plugin`. Start a **new** task afterwards, because the SessionStart hook fires only at session start.
3. Paste the prompt in [`TEST-SCRIPT.md`](TEST-SCRIPT.md), which also holds my results for both products.

Expected hash for the bundled fixture, on any OS:

```
5b8eb08480e0a148bcbc53a2a885618b28fc41d775cb2085320b8cebff72aba7
```

## Things to know

- The `LOCKED` rule is a blunt string match on the whole tool input. While the plugin is installed it will also block an innocent search or command that merely contains that word.
- The trial balance is a synthetic test fixture, not real data.
- The hook log is written to `$CLAUDE_PROJECT_DIR/probe-hook-log.txt`. In a Cowork cloud session that is inside the cloud VM, and it does not reach your disk.
- `docs/SOURCES.md` is the research log behind the write-up: each claim has a URL, a date, a documented / observed / inferred status and a quote-confidence flag. Treat the `F` (fetch-tool) quotes as leads to re-check, not as verified.

## License

MIT. See [LICENSE](LICENSE).
