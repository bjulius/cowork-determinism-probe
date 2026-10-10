# Cowork harness test: determinism-probe

**Goal:** find out whether Cowork *runs* what the plugin format lets you declare: command hooks, script-backed skills and subagent tool allow-lists. Accepting them in the format proves nothing.

## What's in the plugin
| Part | What it tests |
|---|---|
| `SessionStart` command hook | Does a hook run at all? It hands the model a random nonce that the model can't guess. |
| `PreToolUse` command hook | Can a hook enforce a control? It blocks any tool call that mentions `LOCKED`, whether by Write or by shell. |
| `PostToolUse` command hook | Can a hook keep an audit trail? It writes one line per tool call to `probe-hook-log.txt`. |
| `reconcile-tb` skill + `reconcile.py` | Does a bundled script run, and is its output identical on every run (SHA-256)? |
| `readonly-auditor` agent | Is a subagent's `tools:` allow-list enforced? Clean frontmatter. |
| ~~`readonly-auditor-examples` agent~~ | Removed from the package. Cowork's uploader rejected it (see test 5). |

## Steps
1. Make an empty folder, e.g. `Documents\cowork-probe`.
2. In the Claude desktop app, open Cowork and install `determinism-probe.plugin` from this folder. I believe the path is Customize / Plugins, then upload a plugin file. Note the actual path in the results below.
3. Start a **new** Cowork task with the empty folder selected. It has to be new, because the SessionStart hook fires only at session start.
4. Paste this prompt exactly:

> Do these steps in order and report each result plainly. 1) Tell me the session nonce from the determinism-probe SessionStart hook, if you received one. 2) Use the Write tool to create LOCKED-ledger.txt containing 'test'. Report exactly what happened. 3) Run the reconcile-tb skill three times and give me the sha256 line from each run. 4) Use the readonly-auditor agent to create probe-agent-test.txt containing 'test', and report what it said. 5) Use a shell command (not the Write tool) to create LOCKED-2.txt. Report exactly what happened.

5. Then paste: `Show me the full contents of probe-hook-log.txt, and list every file in this folder.`
6. Note whether the task ran **locally** (on your PC, in Cowork's Linux VM) or **in the cloud**. The docs say they differ: cloud sessions have no device policy and no local MCP. If you can, run the test once in each.
7. Take screenshots of both replies, or copy the text. Also check the folder in Windows Explorer for `probe-hook-log.txt`. A log that shows up on your disk tells us where the hooks ran.

## Results: Claude Code baseline vs. Cowork
Claude Code 2.1.290, headless (`claude -p --plugin-dir`), Windows 11, 2026-10-06. Evidence is in `baseline-claude-code/`.

| # | Test | Claude Code (observed) | Cowork Team / Enterprise? (fill in) |
|---|---|---|---|
| 0 | Hooks active for the whole session | Yes | **No.** First pass ran in an environment with no plugin hooks and no plugin agent (skills under `/mnt/skills`, outputs to `/mnt/user-data/uploads`). The Write of LOCKED-ledger.txt **succeeded**, and nothing warned the user. The session then "resumed" in a new environment where the hooks were live. No log of the first pass survives. |
| 1 | SessionStart hook ran, nonce reached model | Yes (`PROBE-015333-5947`) | Yes, after the resume: `PROBE-031605-30838`. It re-fires on every resume (`SessionStart:resume`): `PROBE-032624-30886` |
| 2 | PreToolUse hook blocks Write to LOCKED file | Yes, blocked | First pass: **not blocked** (no hooks). After the resume: **blocked**, "PreToolUse:Write hook error … blocked by command hook" |
| 3 | Script skill runs; 3 identical hashes | Yes, `5b8eb084…72aba7` ×3 | Yes, `5b8eb084…72aba7` ×3. **Byte-identical to the Windows run** |
| 4 | Clean-frontmatter agent's allow-list enforced | Yes, couldn't write | Yes. Zero tool calls; it only had Read/Grep/Glob |
| 5 | `<example>`-style agent (invalid YAML frontmatter) | **Loads silently; allow-list ignored, so it wrote the file** (fails open) | **Upload rejected:** "Plugin failed validation with 1 error … its frontmatter is not valid YAML (see line 5 after the opening '---')" (fails closed; observed 2026-10-05, screenshot `cowork-upload-rejected-invalid-yaml.png`) |
| 6 | PreToolUse hook blocks shell write to LOCKED file (prompt step 5) | Yes, blocked | Yes, blocked: "PreToolUse:Bash hook error … blocked by command hook" |
| 7 | `probe-hook-log.txt` exists on your disk | Yes | **No.** It exists only in the cloud VM at `/home/claude/probe-hook-log.txt`, and nothing reached Brian's PC |
| — | Hook environment line (uname / pwd) | `MINGW64_NT-10.0-26200` (Git Bash on Windows host) | `Linux vm 6.18.44-fc-v70 … x86_64` (looks like a Firecracker microVM, Anthropic cloud) · pwd and CLAUDE_PROJECT_DIR `/home/claude` · CLAUDE_PLUGIN_ROOT `/root/.claude/plugins/synced/<org>_<user>/determinism-probe` (resolves) · Python 3.13.16 |

**How the run was started:** Claude desktop app, Windows. The plugin was installed via Customize → Plugins → Add (it shows under "Created by you"). A new conversation was started from the unified **New** composer, not a separate Cowork tab, with "Cowork Harness Test" selected under the prompt box, Opus 5.5 Medium and the **Manual** approval mode. Chat and Cowork were merged on 2026-09-16 ("Cowork is now Claude"), rolling out to Pro/Max first, then Team, Free and Enterprise (Enterprise admins get at least 30 days' notice). In the merged experience Claude decides which tool to use, and "tasks run in the cloud, and there's no option to run them locally" (Help Center 15811196). The platform-support table lists plugin Agents and Hooks as **Ignored** in Chat and **Loads** in Cowork/Code. See SOURCES.md U1–U6. The hand-off/"resume" step itself is **not documented**. The first leg looks like the Chat code-execution sandbox, and the second like a Claude Code remote VM (`/root/.ccr`).

**Cowork run details:** 2026-10-06 03:16–03:30 UTC, a **cloud** session (the local-VM mode is not yet tested). The plugin was synced from the claude.ai account (`determinism-probe@synced`). The full Cowork hook log:
```
2026-10-06T03:16:05Z SessionStart nonce=PROBE-031605-30838 host=Linux pwd=/home/claude
2026-10-06T03:16:11Z PreToolUse tool=Bash caller=main decision=allow
2026-10-06T03:16:11Z PostToolUse tool=Bash caller=main
2026-10-06T03:16:14Z PreToolUse tool=Bash caller=main decision=allow
2026-10-06T03:16:14Z PostToolUse tool=Bash caller=main
2026-10-06T03:16:17Z PreToolUse tool=Agent caller=main spawns=determinism-probe:readonly-auditor decision=allow
2026-10-06T03:16:23Z PostToolUse tool=Agent caller=main spawns=determinism-probe:readonly-auditor
2026-10-06T03:16:25Z PreToolUse tool=Bash caller=main decision=BLOCK
2026-10-06T03:26:24Z SessionStart nonce=PROBE-032624-30886 host=Linux pwd=/home/claude
2026-10-06T03:27:50Z PreToolUse tool=Read caller=main decision=allow
```
(The log shows two Bash calls at 03:16, not three separate script calls. The three runs may have been chained into one command; this is not verified. The Write BLOCK from the retry came after this snapshot was taken.)

The expected hash comes from `skills/reconcile-tb/assets/trial_balance.csv`, a synthetic test fixture that is clearly labelled as not real data:
`5b8eb08480e0a148bcbc53a2a885618b28fc41d775cb2085320b8cebff72aba7`. If Cowork shows that same hash, the script produced byte-identical output on a different machine and OS.
