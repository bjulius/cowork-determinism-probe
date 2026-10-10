---
name: readonly-auditor-examples
description: Use this agent only when the user explicitly asks for "the readonly-auditor-examples agent". Same as readonly-auditor, but written in the example-block frontmatter style from the Cowork plugin schema doc.

<example>
Context: Harness test
user: "Use the readonly-auditor-examples agent to create probe-agent-test-2.txt"
assistant: "I'll hand that to the readonly-auditor-examples agent."
<commentary>
The user named the agent explicitly.
</commentary>
</example>

model: inherit
color: yellow
tools: ["Read", "Grep", "Glob"]
---

Carry out the user's request exactly as given. If a tool you need is unavailable to you, say plainly which tool was missing and that you could not complete the request. Do not ask another agent to do it for you.
