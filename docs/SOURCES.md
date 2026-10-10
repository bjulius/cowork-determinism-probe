# Cowork vs Claude Code: harness comparison for deterministic workflows (SOURCES)

Research date: 2026-10-05. Read-only research; nothing was tested hands-on in Cowork.

**Quote-confidence key** (applies to the Quote column)
- **V**: verbatim. Copied from the raw Markdown of an official docs page (the `.md` pages on claude.com/docs and code.claude.com return source text, not a summary).
- **F**: the fetch tool returned it in quotation marks as verbatim, but I did not see the raw page. This applies to support.claude.com articles, GitHub issues and typesafe.ai. Re-check before publishing.
- **(paraphrase)**: not a quote.

---

## 1. Executive summary

1. Cowork is Claude Code under the hood. Anthropic's docs say so directly: "Cowork in the Claude Desktop app runs its sessions on Claude Code" (code.claude.com managed-settings). Cowork uses the same plugin format, the same skill format, the same hook schema and the same OTel event names (`tool_decision`, with `source: "hook"`).
2. What differs is the configuration surface. Cowork reads plugins, skills and connectors from the claude.ai account and "doesn't read the Claude Code CLI's `~/.claude` directory". So user `settings.json` hooks, permission rules and CLAUDE.md-style user config from the CLI do not carry over.
3. **Hooks (the key item):** official docs now say plugin hooks load in Cowork (platform-support table: Hooks = "Loads" in Cowork). The 3P extensions page says Cowork sessions "run hooks from marketplace plugins, from plugins in the `org-plugins/` directory, and from plugins users add themselves". The Sept 2026 changelog has a Cowork fix for "an organization hook blocked a message". GitHub issues from Feb–May 2026 (#27398, #51281, #40495, #63360) reported that plugin hooks and settings.json hooks never fired in Cowork. So the docs and the bug reports conflict, and dates matter. As of Oct 2026, the most likely position is that **plugin hooks run but `~/.claude/settings.json` hooks do not**. Only a hands-on test settles it.
4. Org policy works differently in Cowork. Cowork "never fetches server-managed settings from the claude.ai admin console". On the user's machine it reads the device's MDM policy and `managed-settings.json`. In remote/cloud Cowork sessions, or under `requireCoworkFullVmSandbox`, there is no device policy at all. Admins govern Cowork through Organization settings: plugin availability (Required, etc.), connector tool policies, network egress, approval modes, and an OTel endpoint.
5. Cowork has no headless mode: no `claude -p`, no `--json-schema` structured output, no Agent SDK entry point, no Workflow tool. The Workflow tool is documented for the CLI, the Desktop app, the IDE extensions, `-p` and the SDK. Cowork is not listed (not found). Output styles, LSP, plugin `settings` and `bin/` are ignored or blocked in Cowork.
6. Scheduled tasks exist in Cowork. They now run remotely by default, "If a scheduled task requires local files or apps, it will only run locally". Since 2026-10-01 they default to "Automatically approve" where the org allows it.
7. Code execution is sandboxed. Locally, the agent loop runs on the device and code runs in a Linux VM (Hyper-V on Windows, Virtualization.framework on macOS) with egress filtering. In the cloud, everything runs on Anthropic-managed VMs. Local stdio MCP servers do not run in cloud sessions.
8. Audit: Cowork is in the Compliance API (last 30 days) and has its own OTel export, configured separately from Claude Code's. Claude Code has the richer OTel (metrics, events, traces), plus transcripts on disk and `-p` JSON output with cost.
9. **Bottom line for determinism:** in both products the model is non-deterministic, so the numbers must come from scripts. Claude Code can enforce the "model only orchestrates" rule with harness controls: managed hooks, `allowManagedHooksOnly`, deny rules, `-p` with a JSON schema, saved workflow scripts that forbid `Date.now`/`Math.random`, and git. Cowork can run the same skill scripts and, per current docs, plugin hooks. But it has no headless or reproducible entry point, it does not read the `~/.claude` config, its admin-console policy doesn't reach local sessions, and the hooks evidence is conflicting.
10. So Cowork fits **governed, script-backed, human-in-the-loop** workflows (the script computes, Claude runs it, a person reviews). It is not yet suitable as a **harness-enforced, unattended, auditable pipeline** unless an admin delivers a Required org plugin with hooks plus device-level managed settings, and a hands-on test confirms the hooks fire and block.

---

## 2. Per-component table

Columns: Claim | Status | Source URL | Page date | Quote (confidence)

### 2a. Architecture: is Cowork Claude Code?

| Claim | Status | Source URL | Page date | Quote |
|---|---|---|---|---|
| Cowork runs its sessions on Claude Code | documented | https://code.claude.com/docs/en/managed-settings | undated (fetched 2026-10-05) | V: "Cowork in the Claude Desktop app runs its sessions on Claude Code." |
| Cowork uses the same agentic architecture as Claude Code | documented | https://claude.com/docs/cowork/overview | undated | V: "Cowork uses the same agentic architecture that powers Claude Code, accessible within Claude Desktop without opening the terminal." |
| Cowork does not read `~/.claude` (user skills, plugins, settings) | documented | https://claude.com/docs/cowork/overview | undated | V: "Cowork loads the ones enabled for your claude.ai account, synced at session start, and doesn't read the Claude Code CLI's `~/.claude` directory on your machine." |
| Local sessions: agent loop on device, code in a Linux VM | documented | https://support.claude.com/en/articles/14479288-claude-cowork-desktop-architecture-overview | "updated over 2 weeks ago" (~mid-Sep 2026) | F: "The agent loop runs natively on the device." / "inside a dedicated Linux VM, isolated from the host operating system by the platform's hypervisor (Apple Virtualization.framework on macOS, Hyper-V on Windows)." |
| Cloud sessions: agent loop and code on Anthropic infrastructure | documented | same | same | F: "the agent loop and code execution run in an isolated, temporary sandbox on Anthropic-managed infrastructure." |
| Getting-started article describes work running on Anthropic's servers | documented; **conflicts in emphasis** with the architecture article, which describes both local and cloud modes | https://support.claude.com/en/articles/13345190-getting-started-with-cowork | "updated this week" | F: "Claude's work runs in an isolated environment on Anthropic's servers, separate from your computer and your network." |
| Cloud sessions are on by default for Team, off by default for Enterprise | documented | https://support.claude.com/en/articles/13455879-use-cowork-on-team-and-enterprise-plans | "updated today" (2026-10-05) | F: "Team plans: on by default. An owner can turn it off any time from the 'Run Cowork in the cloud' toggle." |
| Earlier (Mar 2026) Cowork ran the CLI inside the VM and missed host settings | documented (bug report) | https://github.com/anthropics/claude-code/issues/40495 | opened 2026-03-29, open | F: "Cowork (local-agent-mode) sessions silently ignore all three settings sources … This means user-defined hooks never fire, enterprise managed policies are not enforced…" |

### 2b. Plugins

| Claim | Status | Source URL | Page date | Quote |
|---|---|---|---|---|
| Same plugin folder works on chat, Cowork and Claude Code; each loads a subset | documented | https://claude.com/docs/plugins/platform-support | undated | V: "You can install the same plugin folder everywhere you use Claude, but chat, Cowork, and Claude Code each load a different subset of what the folder can contain." |
| Cowork loads skills, commands, agents, hooks, remote MCP, and local MCP (when on your computer) | documented | same | undated | V (table rows): Agents "Loads"; Hooks "Loads"; Local MCP server "Loads when the Cowork session runs on your computer" |
| Cowork ignores LSP, output styles, themes and plugin `settings`; `bin/` blocks install | documented | same | undated | V: "LSP servers, output styles, themes, `settings` \| Ignored \| Ignored \| Loads"; "Executables in a top-level `bin/` directory \| Can't be installed \| Can't be installed \| Loads" |
| `${user_config.*}` MCP servers are ignored in Cowork without defaults | documented | same | undated | V: "Ignored when a referenced option has no default; Cowork doesn't prompt for values" |
| Org admin can make a plugin Required (Team and Enterprise) | documented | https://claude.com/docs/plugins/admin | undated | V: "**Required** \| The plugin is installed and always on, marked **This plugin is required by your organization** \| No; members can't turn it off or remove it" |
| Per-group plugin availability is Enterprise only | documented | same | undated | V: "On Enterprise plans, you can give a user group its own availability for a plugin." |
| Members' plugin publishing defaults: Team Open, Enterprise Off → Requires review on 2026-10-02 | documented | same | undated | V: "**Enterprise**: **Off**. On October 2, 2026, the Enterprise default becomes **Requires review**." |
| Version history and rollback for org-uploaded plugins | documented | same | undated | V: "For an item your organization uploads, you can make any earlier version the one members get" |
| Claude Code equivalent is managed settings (allowlist marketplaces, force-install) | documented | https://claude.com/docs/plugins/platform-support | undated | V: "In managed settings, an admin allowlists or blocks marketplaces and force-installs plugins" |
| Plugin installed on the claude.ai account syncs into Claude Code | documented | same | undated | V: "A plugin you install on your account also appears in Claude Code as a synced plugin at the next session start" |
| Local skill authoring guide says hooks are "rarely used in Cowork" and agents are "uncommonly used" | documented (local Anthropic skill) | ~/.claude/plugins/synced/...\cowork-plugin-management\skills\create-cowork-plugin\SKILL.md | synced copy, undated | V: "Hooks (rarely used in Cowork)"; "Agents (uncommonly used in Cowork)"; "This schema is shared with Claude Code's plugin system" |

### 2c. Skills and bundled scripts

| Claim | Status | Source URL | Page date | Quote |
|---|---|---|---|---|
| Skills load in chat, Cowork and Claude Code | documented | https://claude.com/docs/plugins/platform-support | undated | V: "Skills (`skills/<name>/SKILL.md`) \| Loads \| Loads \| Loads" |
| Cowork resolves `${CLAUDE_SKILL_DIR}` for skill scripts | documented | https://claude.com/docs/skills/how-to | undated | V: "Claude Code and Cowork replace `${CLAUDE_SKILL_DIR}` with the skill's folder when the skill loads. It's a placeholder in the skill text, not an environment variable." |
| Scripts are recommended for work more reliable as code | documented | same | undated | V: "Code that Claude runs while following the skill, for work that is more reliable as a program than as instructions." |
| In Claude Code a script run is a permissioned Bash call; can be pinned by an exact-path allow rule | documented | same | undated | V: "a rule that names the exact path approves only that script; a wildcard before the path would approve more than you intend." |
| Recent Cowork fixes to script paths (skills/plugin root blank, "No such file") | documented | https://claude.com/docs/cowork/changelog | 2026-09-17 and 2026-08-27 | V/F: "Fixed plugin skills that reference `${CLAUDE_PLUGIN_ROOT}` or `${CLAUDE_SKILL_DIR}` sometimes running their commands with those paths blank." |
| Whether Cowork honours skill `allowed-tools` / `model` frontmatter | not found | | | |

### 2d. Command hooks (the most important item)

| Claim | Status | Source URL | Page date | Quote |
|---|---|---|---|---|
| Claude Code: hooks give deterministic control | documented | https://code.claude.com/docs/en/hooks-guide | undated | V: "Hooks are user-defined shell commands. Claude Code runs them at specific points in its lifecycle, which gives you deterministic control: certain actions always happen rather than relying on the LLM to choose to run them." |
| Claude Code: exit 2 blocks; even an "allow" JSON can't override | documented | https://code.claude.com/docs/en/hooks | undated | F: "On events that can block, exit 2 blocks whether or not you print JSON: even a JSON `permissionDecision` of `"allow"` can't override it." |
| Claude Code: `allowManagedHooksOnly` blocks user, project, local and plugin hooks | documented | same | undated | F: "Administrators can use `allowManagedHooksOnly` in managed settings to restrict which hooks run: Your user, project, local, and plugin hooks are blocked." |
| Platform table: plugin hooks "Load" in Cowork | documented (says "Loads", not explicitly "fires") | https://claude.com/docs/plugins/platform-support | undated | V: "Hooks (`hooks/hooks.json`) \| Ignored \| Loads \| Loads" |
| Support article: hooks run in Cowork and Claude Code | documented | https://support.claude.com/en/articles/13837440-use-plugins-in-claude | "updated over a week ago" | F: "Hooks and sub-agents run in Cowork and Claude Code, not in chat, so they appear grayed out in chat." |
| 3P extensions doc: Cowork sessions run plugin hooks from marketplace, org-plugins and user-added plugins | documented (3P page; probably shared engine, but first-party applicability is inferred) | https://claude.com/docs/third-party/claude-desktop/extensions | undated | V: "**Cowork sessions** run hooks from marketplace plugins, from plugins in the `org-plugins/` directory, and from plugins users add themselves." |
| Same page: device managed settings govern those hooks (`disableAllHooks`, `allowManagedHooksOnly`) | documented (3P page) | same | undated | V: "Claude Code managed settings deployed on the device govern these hooks as they do in the Claude Code CLI: `disableAllHooks` turns them off, and `allowManagedHooksOnly` keeps only the hooks those managed settings define." |
| Same page: blocking UserPromptSubmit works; title request bypasses hooks | documented (3P page) | same | undated | V: "A `UserPromptSubmit` hook that blocks a prompt stops that turn and shows the hook's reason to the user. … That request does not pass through plugin hooks, so a first message that a hook blocks still reaches your provider for titling." |
| Changelog: Cowork fix for an org hook blocking a message (implies org hooks execute in Cowork) | documented (inference that they execute) | https://claude.com/docs/cowork/changelog | v1.52386.0, 2026-09-10, Cowork section | V/F: "Fixed a session appearing stuck running when an organization hook blocked a message; the reason the message was blocked is now shown." |
| Changelog: org-plugin hooks extended to Chat "matching Cowork and Code" | documented | same | early Sept 2026, 3P section (two fetches disagreed between v1.49585.0 / 2026-09-08 and v1.52386.0 / 2026-09-10) | V/F: "Changed hooks from organization plugins to also run in Chat, matching Cowork and Code." |
| Changelog: with `disableSideloadFlags`, Cowork-on-device loads no desktop plugins, so no plugin hooks | documented | same | v1.44121.1, 2026-09-02, Cowork | V/F: "in those sessions Claude Code loads none of the desktop's plugins, so their commands, agents, and hooks are unavailable." |
| **Conflict:** plugin hooks.json never fired in Cowork (Windows) | documented bug, closed as duplicate | https://github.com/anthropics/claude-code/issues/27398 | opened 2026-02-21 (Desktop v1.1.3770, CC 2.1.49) | F: "Plugin hooks defined in `hooks/hooks.json` are never discovered or fired in Cowork Desktop sessions. Skills, commands, and MCP servers from the same plugin load and work correctly." / "spawns the Claude CLI process with `--setting-sources user`" |
| **Conflict:** PreToolUse/PostToolUse/SessionStart plugin hooks silently ignored in Cowork | documented bug, closed "not planned" | https://github.com/anthropics/claude-code/issues/51281 (via claudeissues.com mirror) | opened 2026-04-20 | (paraphrase) the plugin loads and skills and MCPs work, but hooks never fire and nothing is logged |
| **Conflict:** SessionStart hooks (settings.json or plugins) don't fire in Cowork | documented bug, closed as duplicate of #40495 | https://github.com/anthropics/claude-code/issues/47993 | opened 2026-04-14 | F: "Cowork sessions do not fire SessionStart hooks defined in ~/.claude/settings.json or in plugins." |
| settings.json hooks (UserPromptSubmit, Stop) don't fire in Cowork; no `/hooks` command | documented bug, closed "not planned" | https://github.com/anthropics/claude-code/issues/63360 | opened 2026-05-28 | F: "Cowork is built on Claude Code, but does not fire these hooks." / "There is no /hooks command in Cowork" |
| **My read:** `~/.claude/settings.json` hooks don't run in Cowork by design (Cowork doesn't read `~/.claude`). Plugin and org-plugin hooks appear to run as of Aug–Sep 2026. | inferred | combination of the rows above | | (paraphrase) |
| Whether plugin hooks fire in **cloud/remote** Cowork sessions or scheduled tasks | not found | | | |
| Where Cowork hook commands execute (host vs VM), and the OS/shell they run in | not found (first-party) | | | |

### 2e. Prompt / agent (LLM-judged) hooks

| Claim | Status | Source URL | Page date | Quote |
|---|---|---|---|---|
| Claude Code supports `prompt` and `agent` hook types | documented | https://code.claude.com/docs/en/hooks | undated | F: "Send a prompt to a Claude model for single-turn evaluation." / "Spawn a subagent that can use tools like Read, Grep, and Glob to verify conditions before returning a decision." |
| These are judgment-based, not deterministic | documented | https://code.claude.com/docs/en/hooks-guide | undated | V: "For decisions that require judgment rather than deterministic rules, you can also use prompt-based hooks or agent-based hooks that use a Claude model to evaluate conditions." |
| Local Cowork plugin-authoring skill recommends prompt hooks "for complex logic" | documented (local) | create-cowork-plugin\SKILL.md and references\component-schemas.md | undated | V: "Prefer prompt-based hooks for complex logic." / "**Prompt-based** (recommended for complex logic)" |
| Prompt hooks specifically confirmed working in Cowork | not found | | | |

### 2f. Subagents (tool allow-lists, pinned model)

| Claim | Status | Source URL | Page date | Quote |
|---|---|---|---|---|
| Plugin agents load in Cowork | documented | https://claude.com/docs/plugins/platform-support | undated | V: "Agents (`agents/*.md`) \| Ignored \| Loads \| Loads" |
| Cowork advertises sub-agent coordination | documented | https://claude.com/docs/cowork/overview | undated | V: "**Sub-agent coordination** — Complex work gets divided into smaller tasks with parallel workstreams for faster results." |
| Claude Code subagents support `tools` allowlist, `disallowedTools`, `model`, `effort` | documented | https://code.claude.com/docs/en/sub-agents | undated | (paraphrase) the frontmatter fields are `tools` (allowlist), `disallowedTools`, `model` (alias, full ID or `inherit`), `effort` |
| Plugin subagents ignore `hooks`, `mcpServers`, `permissionMode` (Claude Code) | documented | same | undated | (paraphrase) these three fields are ignored when the agent loads from a plugin |
| Cowork honours a plugin agent's `tools` and `model` frontmatter | not found | | | |

### 2g. MCP servers

| Claim | Status | Source URL | Page date | Quote |
|---|---|---|---|---|
| Local (stdio) plugin MCP runs in Cowork only when the session is on your computer | documented | https://claude.com/docs/plugins/platform-support | undated | V: "Loads when the Cowork session runs on your computer" |
| Local MCP servers don't run in cloud sessions | documented | https://support.claude.com/en/articles/14479288-claude-cowork-desktop-architecture-overview | ~Sep 2026 | F: "Local MCP servers don't run in sessions in the cloud." |
| In Cowork, connectors reach services via Anthropic's cloud | documented | https://support.claude.com/en/articles/13837440-use-plugins-in-claude | ~late Sep 2026 | F: "In Cowork, connectors reach external services through Anthropic's cloud, not through your local network." |
| Enterprise admin may disable local MCP entirely | documented | same | same | F: "If your organization is on an Enterprise plan, your admin may have restricted which plugins you can install, or disabled local MCP servers entirely." |
| MDM key `isLocalDevMcpEnabled` controls local MCP | documented | architecture article above | ~Sep 2026 | (paraphrase) |
| Connector tool policy "Restrict to Ask" enforced in Cowork, even in Skip-all-approvals | documented | https://claude.com/docs/cowork/changelog | v2.16120.0, 2026-09-29, Cowork | V/F: "a connector tool set to "Restrict to Ask" now asks for your approval, including in "Skip all approvals" mode (newly started tasks only)" |

### 2h. Permissions, permission modes, managed settings, enterprise policy

| Claim | Status | Source URL | Page date | Quote |
|---|---|---|---|---|
| Cowork never fetches server-managed settings | documented | https://code.claude.com/docs/en/managed-settings | undated | V: "In a Cowork session, Claude Code never fetches server-managed settings from the claude.ai admin console, even when the user signs in with a Team or Enterprise account" |
| On-device Cowork reads device MDM and `managed-settings.json` | documented | same | undated | V: "**On the user's machine**: by default, Claude Code in a Cowork session reads the MDM or OS-level policy and the managed settings file on that device, so deploy policy there." |
| Full-VM sandbox and remote Cowork have no device policy | documented | same | undated | V: "Claude Code runs inside a virtual machine where the device's MDM policy and managed settings file aren't present." / "**Remote Cowork sessions**: these run on Anthropic-managed VMs, where Claude Code has no device policy to read." |
| `allowManagedPermissionRulesOnly` breaks Cowork folder writes unless folders are allow-listed in managed policy | documented | same | undated | V: "In a Cowork session that asks before edits, Cowork can't show the prompt, and Claude reports each write as blocked" |
| Surface coverage table: MDM/managed file "Enforced where deployed" for Cowork | documented | https://code.claude.com/docs/en/model-config | undated | F: "Remote Cowork sessions: the server checks the model. On the user's machine: not delivered." (server-managed column) / "Enforced where deployed" (MDM column) |
| Cowork approval modes: Manual / Auto / Skip | documented | https://support.claude.com/en/articles/13345190-getting-started-with-cowork | "updated this week" | F: "**Skip**: "Claude doesn't pause to ask and nothing checks its actions automatically"" |
| **Conflict:** "Automatically approve" / "Skip all approvals" not available for Enterprise orgs (3P feature matrix), versus an org setting controlling Automatically approve (T&E article) | conflicting | https://claude.com/docs/third-party/claude-desktop/feature-matrix vs https://support.claude.com/en/articles/13455879 | undated / 2026-10-05 | V: "¶ Cowork's Automatically approve and Skip all approvals modes are not available for Claude Enterprise organizations." |
| Scheduled tasks Claude creates default to Automatically approve where allowed | documented | https://claude.com/docs/cowork/changelog | v2.19675.0, 2026-10-01 | V/F: "Changed scheduled tasks that Claude creates for you to use "Automatically approve" by default where your organization allows it" |
| `disableBypassPermissionsMode`, `builtinToolPolicy`, `disabledBuiltinTools` (MDM keys, apply to Cowork and Code) | documented (on 3P config page; first-party applicability unclear) | https://claude.com/docs/third-party/claude-desktop/configuration | undated | V: `disabledBuiltinTools`: "Built-in tools, or argument-scoped permission rules such as Read(//\*\*/.env), denied in Cowork and Code." |
| `organizationInstructions` is guidance, not a control | documented | same | added 1.37937.0 | V: "Guidance the model follows, not an enforced control." |
| A user-editable Cowork `settings.json` with allow/deny/ask rules | not found (Cowork doesn't read `~/.claude`) | | | |

### 2i. Memory and instructions (CLAUDE.md equivalent)

| Claim | Status | Source URL | Page date | Quote |
|---|---|---|---|---|
| Cowork has global instructions (Settings > Cowork / "Instructions for Claude") | documented | https://support.claude.com/en/articles/13345190-getting-started-with-cowork | "updated this week" | F: "You can give Claude standing instructions that apply to every Cowork session." |
| Folder instructions exist; Claude can update them | documented (paraphrase only) | same | same | (paraphrase) |
| Cowork projects bundle folders, instructions, links and a project memory; local only | documented | https://claude.com/docs/cowork/guide/projects | undated | V: "Projects live on your computer. They aren't synced to the cloud or shared with other people." |
| Folder instructions are a `CLAUDE.md` at the folder root | secondary sources only | https://go9x.com/blog/how-to-set-up-claude-cowork and other blogs (search snippets) | undated | (paraphrase) |
| All of these are model guidance, not harness-enforced | inferred (the docs say this explicitly for `organizationInstructions`) | | | |

### 2j. Headless / non-interactive / structured output

| Claim | Status | Source URL | Page date | Quote |
|---|---|---|---|---|
| Claude Code: `claude -p` with `--json-schema` returns `structured_output` | documented | https://code.claude.com/docs/en/headless | undated | V: "To get output conforming to a specific schema, use `--output-format json` with `--json-schema` and a JSON Schema definition." |
| Claude Code: `--bare` for the same result on every machine | documented | same | undated | V: "Bare mode is useful for CI and scripts where you need the same result on every machine." |
| Claude Code: `dontAsk` mode for locked-down CI | documented | same | undated | V: "**`dontAsk`**: Claude Code denies every call that would otherwise prompt, which is useful for locked-down CI runs." |
| A Cowork headless / CLI / SDK entry point | not found | | | |

### 2k. Scheduled tasks / routines

| Claim | Status | Source URL | Page date | Quote |
|---|---|---|---|---|
| Cowork scheduled tasks on all paid plans; run remotely | documented | https://support.claude.com/en/articles/13854387-schedule-recurring-tasks-in-cowork | "updated this week" | F: "Scheduled tasks run remotely, so they run on their cadence even when your computer is asleep or the Claude Desktop app is closed." |
| Local-file tasks run locally only | documented | same | same | F: "If a scheduled task requires local files or apps, it will only run locally." |
| Admin can disable scheduled tasks (`scheduledTasksEnabled`) | documented (3P section of changelog) | https://claude.com/docs/cowork/changelog | v2.110.0, 2026-09-15 | V/F: "set it to `false` to turn off scheduled tasks in Cowork and Code" |
| Claude Code routines: cloud, schedule/API/GitHub triggers, research preview | documented | https://code.claude.com/docs/en/routines | undated | V: "Routines are in research preview." / "Routines execute on Anthropic-managed cloud infrastructure, or on your organization's self-hosted environment when routed there" |
| Routines run without approval prompts | documented | same | undated | V: "there is no permission-mode picker, and the session runs shell commands … all without stopping for approval apart from some artifact actions." |

### 2l. Workflow tool (deterministic multi-agent orchestration)

| Claim | Status | Source URL | Page date | Quote |
|---|---|---|---|---|
| A workflow is a script the runtime executes; the script decides what runs next | documented | https://code.claude.com/docs/en/workflows | undated | V: "A workflow moves the plan into code." |
| Determinism aids: `Date.now()`, `Math.random()` throw; schema-validated agent output | documented | same | undated | V: "Claude Code makes `Date.now()`, `Math.random()`, and a no-argument `new Date()` throw inside the script, so that a relaunched run repeats the same `agent()` calls." |
| Surfaces: CLI, Desktop app, IDE, `-p`, SDK. **Cowork not listed.** | documented (Cowork absence = not mentioned) | same | undated | V: "Workflows are available in the CLI, the Desktop app, the IDE extensions, non-interactive mode with `claude -p`, and the Agent SDK." |
| Workflow tool in Cowork | not found | | | |

### 2m. Output styles, worktrees, checkpoints

| Claim | Status | Source URL | Page date | Quote |
|---|---|---|---|---|
| Plugin output styles ignored in Cowork | documented | https://claude.com/docs/plugins/platform-support | undated | V: "LSP servers, output styles, themes, `settings` \| Ignored \| Ignored \| Loads" |
| Output styles added to Desktop **Code tab** | documented | https://claude.com/docs/cowork/changelog | v1.44121.1, 2026-09-02, Code section | V/F: "Added Claude Code output styles: an "Output style" submenu in the session menu and a `/output-style` command" |
| Claude Code checkpoints don't track Bash changes; not version control | documented | https://code.claude.com/docs/en/checkpointing | undated | V: "Checkpointing does not track files modified by Bash commands." / "For permanent version history and collaboration, continue using version control" |
| Cowork: Edit/resend the last message (Cowork and Chat, 3P section) | documented | changelog | v1.46388.1, 2026-09-04 | (paraphrase) |
| Cowork file checkpoints/rewind, or git worktrees | not found | | | |

### 2n. Execution sandbox and network

| Claim | Status | Source URL | Page date | Quote |
|---|---|---|---|---|
| VM egress filtering via a mandatory proxy | documented | https://support.claude.com/en/articles/14479288 | ~Sep 2026 | F: "a mandatory proxy the sandbox can't reconfigure or bypass, and only allow-listed destinations are reachable." |
| Org egress settings apply at session creation and don't cover web fetch/search | documented | https://support.claude.com/en/articles/13455879 | 2026-10-05 | F: "Network egress permissions don't apply to the web fetch or web search tools." |
| **Conflict:** the architecture article says egress doesn't apply to web search **or MCPs** (search snippet only) | conflicting / unverified | https://support.claude.com/en/articles/14479288 (search snippet) | | (paraphrase) |
| Admin location: Admin settings > Capabilities > Network egress; OTel collector auto-allowlisted | documented | https://claude.com/docs/cowork/monitoring | undated | V: "The OTel exporter runs inside the Cowork VM, so it is subject to the session's egress rules." |
| `coworkEgressAllowedHosts` MDM key | documented (config page; first-party applicability unclear) | https://claude.com/docs/third-party/claude-desktop/configuration | added 1.2581.0 | V: "Hostnames the agent's tools may reach from Cowork and Code sessions." |
| Windows supported (Hyper-V); Windows Home reportedly unsupported | documented (Hyper-V) / bug report (Home) | architecture article; https://github.com/anthropics/claude-code/issues/27906 | | (paraphrase) |
| Attachable folders now include home, Documents, whole drives; credential locations stay off-limits | documented | changelog | v1.46388.3, 2026-09-04, Cowork | V/F: "Claude's own configuration and session data inside them stay off-limits, as do certain credential and shell-startup locations" |
| Third-party security research on a Cowork VM sandbox escape ("SharedRoot") | secondary | https://labs.cloudsecurityalliance.org/research/csa-research-note-claude-cowork-sharedroot-sandbox-escape-20/ | 2026-07-24 | not read in full |

### 2o. Model selection and effort

| Claim | Status | Source URL | Page date | Quote |
|---|---|---|---|---|
| Cowork has a model picker and effort control (extended-thinking switch beside effort, 3P) | documented | changelog | v2.9939.2, 2026-09-24 | V/F: "Added the extended-thinking switch beside the effort control in the Cowork message box." |
| Admin can turn models off; `availableModels` enforced server-side only for remote Cowork | documented | https://code.claude.com/docs/en/model-config | undated | F: "When the `availableModels` list in your server-managed settings is non-empty and a user picks a model outside it, the server rejects that model for a remote Cowork session." |
| Scheduled task setup lets the user pick the model | documented | scheduled-tasks support article | this week | (paraphrase) |
| Pinning a dated model ID in Cowork (vs alias) | not found | | | |

### 2p. Audit and observability

| Claim | Status | Source URL | Page date | Quote |
|---|---|---|---|---|
| Cowork OTel export (Team and Enterprise), events: user_prompt, assistant_response, tool_result, api_request, api_error, tool_decision | documented | https://claude.com/docs/cowork/monitoring | undated | V: "Monitoring is available for Team and Enterprise plans." |
| Cowork OTel records whether a hook made the permission decision | documented | same | undated | V: `source` — "`"config"`, `"hook"`, `"user_permanent"`, `"user_temporary"`, `"user_abort"`, or `"user_reject"`" |
| Cowork OTel is configured separately from Claude Code's | documented | https://code.claude.com/docs/en/monitoring-usage | undated | F: "The OpenTelemetry form for Cowork … applies to Cowork sessions only, so neither the terminal CLI nor the Code tab exports to a collector you set there." |
| Cowork is in the Compliance API (30 days) | documented | https://support.claude.com/en/articles/13455879 | 2026-10-05 | F: "Cowork sessions via Claude, Claude Desktop, and Claude Mobile are captured in the Compliance API." / "returns sessions from the most recent 30 days." |
| Compliance API not available on 3P | documented | https://claude.com/docs/third-party/claude-desktop/feature-matrix | undated | V: "Compliance API \| ✓ \| — ‡" |
| Claude Code OTel: metrics, events, optional traces; hook span only with detailed beta tracing | documented | https://code.claude.com/docs/en/monitoring-usage | undated | F: "A `claude_code.hook` span appears only when detailed beta tracing is active" |
| Session retention keys `coworkSessionRetentionDays` and legal hold (3P section) | documented | changelog | 2026-09-10 | (paraphrase) |

### 2q. Other harness pieces relevant to auditable workflows

| Claim | Status | Source URL | Page date | Quote |
|---|---|---|---|---|
| Admin-pinned marketplaces require a commit SHA / manifest hash for auto-install, so content is "deterministic and auditable" | documented (3P page) | https://claude.com/docs/third-party/claude-desktop/extensions | undated | V: "`"auto_install"` and `"required"` marketplaces must carry an admin-side content pin so the exact plugin content deployed to every device is deterministic and auditable." |
| Marketplace fetch happens on the host, outside the Cowork VM | documented (3P page) | same | undated | V: "Claude Desktop fetches marketplaces on the host operating system, outside the Cowork VM." |
| The "org-plugins" directory path doesn't load hooks in Code-tab sessions | documented (3P page) | same | undated | V: "Code sessions do not load their skills, commands, sub-agents, or hooks" |

---

## 3. typesafe.ai: "Introducing System One Models and Jev"

URL: https://typesafe.ai/blog/introducing-system-one-models-and-jev. Byline: Diogo Almeida, founder, TypeSafe. Dated Sep 15, 2026 (byline and date are F).

**Summary (paraphrase).** TypeSafe argues that LLMs are superhuman at chat but have produced little real automation, because software can't depend on free-text output that may hallucinate or contain type errors. It introduces "System One" models. Its first public one, Jev, gives up free-text generation and instead returns structured values whose possible outputs are fixed in advance, with calibrated confidence scores. TypeSafe claims Jev is about two orders of magnitude faster than frontier LLMs on such tasks.

**Bearing on deterministic workflows (my inference).** The post agrees with the "model only orchestrates" premise: the output contract should be fixed by the system, not left to the model. But schema-constrained output with confidence scores gives *well-typed*, not *deterministic*, output; the word "deterministic" does not appear in the post. For a CPA it suggests a role for narrow judgment calls, like classifying a transaction with a confidence threshold that routes to review. The arithmetic and file outputs still belong in scripts, and the harness still has to enforce the gates.

Confirmed lines (F): "Models have been superhuman at chat for years, so where is all the automation?" / "While Jev gives up string generation, it's optimized for structured outputs and *can't* hallucinate." / "Having a hallucinated tool call is inconvenient in an agent, but is an absolute deal-breaker if it's part of a system with latency guarantees or it's buried several layers deep in a dependency chain."

---

## 4. Open questions that only a hands-on Cowork test can settle

1. **Do plugin command hooks fire in first-party (non-3P) Cowork today, on Windows and macOS?** Test: a plugin with a `PreToolUse` hook on `Write|Edit|Bash` that appends to a log and exits 2 on a forbidden path. Check that the log is written and the call is blocked, and look for `source: "hook"` in OTel `tool_decision`.
2. Which events fire: SessionStart, UserPromptSubmit, PreToolUse, PostToolUse, Stop, SubagentStop? The bug reports name SessionStart and Stop specifically.
3. Where does a Cowork hook command execute: host OS or the Linux VM? Which interpreter is on PATH (bash, python3, PowerShell)? What file access does it have? This decides whether a Windows-authored hook script works at all.
4. Do plugin hooks fire in **cloud/remote** Cowork sessions and in **remotely run scheduled tasks**? The docs are silent, and remote sessions have no device policy.
5. Does a device-level `managed-settings.json` with `hooks` and `allowManagedHooksOnly` take effect in a local first-party Cowork session, as the managed-settings doc implies?
6. Does a Required org plugin's hook survive the user switching approval mode to Skip or Automatically approve? Does a hook `deny` override an "Automatically approve" decision?
7. Do `prompt`/`agent` hook types work in Cowork, or only `command`?
8. Does Cowork honour plugin-agent frontmatter: the `tools` allowlist, a pinned `model`, `effort`?
9. Does Cowork read `CLAUDE.md` / `AGENTS.md` in a connected folder automatically, and with what precedence against global and project instructions?
10. Can a skill script produce byte-identical output files across two Cowork runs on the same inputs? Check the VM's Python/Node versions and preinstalled packages, and whether they change between workspace updates. Can the version be pinned?
11. Does `${CLAUDE_PLUGIN_ROOT}` resolve correctly in hook commands, not just in skills? The Sept 17 fix covered skills.
12. Enterprise conflict: are "Automatically approve" and "Skip all approvals" actually unavailable on Claude Enterprise (3P feature matrix), or admin-controllable (T&E support article)?
13. Is any Workflow-tool-like orchestration available in Cowork, or does multi-step work always depend on the model?
14. What does the Compliance API return for a Cowork session: tool inputs and outputs, hook decisions, the files written?

---

## Unified Chat/Cowork (late Sept-Oct 2026)

Research date: 2026-10-05. Same rules as above: V = verbatim from raw docs Markdown; F = returned in quotation marks by the fetch tool but not seen on the raw page; (paraphrase) = not a quote.

**Caveat on the desktop changelog.** I fetched claude.com/docs/cowork/changelog four times. The bullet text was identical every time, but the version and date assigned to the same bullet changed between fetches. The page is long and the fetch tool summarises it, so the dates below come with ranges.

### U1. Did Anthropic merge Chat and Cowork?

| Claim | Status | Source URL | Page date | Quote |
|---|---|---|---|---|
| Yes. Official announcement: Cowork and chat merge into one Claude | documented | https://claude.com/blog/cowork-is-now-claude | 2026-09-16 | F: "It's rolling out on Pro and Max plans over the next few weeks" / "Team and Free plans will follow soon" |
| Release-notes entry "Claude Cowork comes to every conversation" | documented | https://support.claude.com/en/articles/12138966-release-notes | entry dated 2026-09-16 | F: "everything Claude Cowork does available from any conversation" / "Your chats, Cowork tasks, projects, connectors, and skills carry over." |
| Help Center article "Claude Cowork and chat are one Claude" | documented | https://support.claude.com/en/articles/16761823 | "updated over 2 weeks ago" | F: "in the new experience, these are merged into a single conversation, so you don't need to decide which option better suits your task" |
| Plans: Pro and Max first; others later; Enterprise gets 30 days' notice | documented | same | same | F: "The new Claude experience is rolling out gradually, starting with Pro and Max plans on web, desktop, and mobile. More plans will follow soon, and Enterprise admins will hear from us at least 30 days before anything changes" |
| Anthropic's stated reason | documented (9to5Mac quoting Anthropic) | https://9to5mac.com/2026/09/16/anthropic-merging-claude-cowork-with-chat/ | 2026-09-16 | F: "People used both, and told us the frustrating part was deciding where a task belonged." |
| Brian's test (desktop "New" composer with a project and folder picked) is consistent with being in the new experience. Whether his plan has it officially is not confirmed. | inferred | | | |

### U2. How the handoff works

| Claim | Status | Source URL | Page date | Quote |
|---|---|---|---|---|
| Claude decides which tool or capability a task needs | documented | https://support.claude.com/en/articles/16761823 | ~mid-Sep 2026 | F: "Ask Claude for what you need, and it can decide which tool to use." |
| Longer tasks keep running in the cloud | documented | same | same | F: "More involved tasks keep running in the cloud even if you close your laptop or leave the page." |
| The result comes back in the same conversation | documented | same | same | F: "Come back when the task is done, and the result is waiting in the conversation." |
| The decision rule for when a chat escalates to an agent/Cowork session | not found | blog, Help Center, release notes, 9to5Mac, TestingCatalog all checked | | The Help Center article doesn't describe the mechanism (fetch reported "does not explain how a conversation becomes a longer task or moves to the cloud") |
| A UI indicator, or a user control to force or prevent escalation | not found | same | | |
| A documented "resume" / "pick up" step between two environments | not found | same | | Brian's observation of a `SessionStart source=resume` in a second environment is **not documented anywhere I found**. |
| Cloud sessions run in Firecracker microVMs | secondary only | https://dev.classmethod.jp/en/articles/claude-managed-agent-sandbox-run-on-firecracker/ ; https://baeseokjae.github.io/posts/claude-web-antspace-microvm-2026/ | | (paraphrase) Firecracker-based cloud sandboxes for Claude Managed Agents / Claude Code on the web. Not stated for Cowork by Anthropic. |
| `/root/.ccr` path | not found | | | |

### U3. Plugin hooks and agents in the Chat leg

| Claim | Status | Source URL | Page date | Quote |
|---|---|---|---|---|
| First-party docs: plugin hooks and agents are **ignored in Chat** | documented | https://claude.com/docs/plugins/platform-support | undated, re-fetched 2026-10-05 (no "new experience" wording on page) | V: "Agents (`agents/*.md`) \| Ignored \| Loads \| Loads" / "Hooks (`hooks/hooks.json`) \| Ignored \| Loads \| Loads" |
| Definition of "Chat" on that page includes the desktop app | documented | same | same | V: "**Chat**: conversations in claude.ai on the web, in the Claude desktop app, and in the mobile apps" |
| Chat runs skills by copying the whole skill folder into the code-execution sandbox | documented | https://claude.com/docs/skills/how-to | undated | V: "In chat on claude.ai, the skill's whole folder, scripts included, is copied into the code execution sandbox" |
| Help Center says hooks and sub-agents don't run in chat | documented | https://support.claude.com/en/articles/13837440-use-plugins-in-claude | ~late Sep 2026 | F: "Hooks and sub-agents run in Cowork and Claude Code, not in chat, so they appear grayed out in chat." |
| Changelog: **organization-plugin** hooks now also run in Chat. This is in the **3P** (third-party provider deployments) section, not first-party. | documented, 3P-scoped | https://claude.com/docs/cowork/changelog | **date unresolved:** fetches placed it under v1.49585.0 (2026-09-08), v1.52386.0 (2026-09-10) and v1.46388.0 (2026-09-10). Best estimate is 2026-09-08 to 09-10. | V/F (bullet text stable across 4 fetches): "Changed hooks from organization plugins to also run in Chat, matching Cowork and Code." |
| 3P extensions page confirms the Chat hook behaviour, with a version | documented, 3P-scoped | https://claude.com/docs/third-party/claude-desktop/extensions | undated | V: "**Chat conversations** run hooks from the same plugins as Cowork sessions, on Claude Desktop 1.52386.0 or later." |
| Related Cowork bullet: org hook blocking a message | documented | changelog | **date unresolved:** fetches gave 2026-09-10 (twice) and 2026-08-18 (once) | V/F: "Fixed a session appearing stuck running when an organization hook blocked a message; the reason the message was blocked is now shown." |
| **Reconciliation (inferred):** Brian saw no hooks or agents in the first leg (`/mnt/skills`, `/mnt/user-data`, the claude.ai code-execution layout) and hooks live after the resume in a cloud VM with plugins synced. That matches the first-party docs: Chat ignores hooks and agents, Cowork loads them. The 3P "org hooks run in Chat" change doesn't apply to a first-party account. | inferred | | | |

### U4. "Manual" approval mode and project/folder selector in the unified composer

| Claim | Status | Source URL | Page date | Quote |
|---|---|---|---|---|
| Permission setting in the message box: Manual (default) and Auto | documented | https://support.claude.com/en/articles/16761823 | ~mid-Sep 2026 | F: "A permission setting in the message box controls how independently Claude works" / "Manual (default): Claude asks before it takes actions, and you choose whether to allow each one." / "Auto: Claude keeps working without stopping to ask about each step, and automated safety checks run before it takes an action." |
| No "Skip" option is listed for the new experience. The older Cowork article lists Manual / Auto / Skip. | documented absence (only Manual and Auto found) | same vs https://support.claude.com/en/articles/13345190 | | (paraphrase) |
| Projects hold files, instructions and context | documented | https://support.claude.com/en/articles/16761823 | same | F: "Projects keep files, instructions, and context together for related work" |
| Local folder access through Claude Desktop | documented | same | same | F: "Tasks that use files or apps on your computer need Claude Desktop open." |
| Where the project/folder selector sits in the unified composer | not found | | | The fetch reported that the article "does not specify how users select a project or folder" |

### U5. Cloud vs local VM: how it's chosen

| Claim | Status | Source URL | Page date | Quote |
|---|---|---|---|---|
| In the new experience, tasks run in the cloud with no local option | documented | https://support.claude.com/en/articles/15811196-what-to-expect-with-claude-cowork-in-the-cloud | "updated over 2 weeks ago" | F: "If you have the new Claude experience, tasks run in the cloud, and there's no option to run them locally." |
| Pre-merge toggle (old experience) | documented | same | same | F: "switch modes when starting a new session by clicking the 'Beta' button in the upper right corner, or by navigating to Settings > Cowork and toggling Run new tasks in the cloud on or off." |
| Local resources reached from a cloud session through the open desktop app | documented | same | same | F: "Some capabilities reach things on your computer, so they require the Claude Desktop app to be open and connected, even when your session runs in the cloud: Local files and folders, Local MCP servers, including plugins that bundle them, Browser use, through Claude in Chrome, Computer use." |
| **Conflict:** the architecture article says local MCP servers don't run in cloud sessions | conflicting | https://support.claude.com/en/articles/14479288 vs 15811196 | | F (14479288): "Local MCP servers don't run in sessions in the cloud." |
| Working files not kept after the session | documented | 15811196 | same | F: "Working files it doesn't hand back aren't kept or referenced after the session ends." |
| Cloud-created scheduled tasks can't use local folders or connectors | documented | same | same | F: "Scheduled tasks created in the cloud can't use local folders or local connectors." |
| From Oct 6 2026, new Cowork tasks on Pro and Max run in the cloud and the local-only option disappears | secondary only (no Anthropic source found for the date) | https://www.clickforest.com/en/blog/claude-desktop-explained | updated 2026-10-03 | F: "from 6 October new Cowork tasks on Pro and Max run in the cloud; the option to work only on your computer disappears." |
| Cloud runs mean no device policy: `managed-settings.json` and MDM don't apply in remote Cowork | documented (from section 2h) | https://code.claude.com/docs/en/managed-settings | undated | V: "**Remote Cowork sessions**: these run on Anthropic-managed VMs, where Claude Code has no device policy to read." |

### U6. What this means for deterministic workflows (inferred)

- In the unified experience, one conversation can span two harnesses. The chat leg runs in the code-execution sandbox, which loads skills but ignores plugin hooks and agents. The Cowork/agent leg runs in an Anthropic cloud VM, which loads plugin hooks and agents. Claude decides when the switch happens, and I found no documented rule or control for it. So **controls that live in hooks are not guaranteed for the whole conversation**. Work done before the handoff is unguarded.
- New-experience tasks run in the cloud by default with no local option. That means no device `managed-settings.json` or MDM policy, so `allowManagedHooksOnly` and device permission rules don't reach them. The enforcement left is account-side: Required org plugins with hooks, org connector tool policies, egress settings, and the Manual approval mode.
- A deterministic setup on the unified experience would need: the computation kept in skill scripts (these run in both legs); hooks treated as a cloud-leg backstop, not the only gate; and a check, built into every workflow, that the hooks fired. Brian's `SessionStart source=resume` marker is one candidate for that check.
