# Philosophy: Why Three Primitives?

Base Coat uses three complementary primitives — **agents**, **skills**, and **instructions** — because each solves a different problem:

| Primitive       | What it is                      | When it activates              | Analogy                  |
|-----------------|---------------------------------|--------------------------------|--------------------------|
| **Agent**       | A persona with a workflow       | When explicitly invoked        | A specialist on your team |
| **Skill**       | A knowledge pack with templates | When attached to a conversation | A reference manual       |
| **Instruction** | A set of rules and standards    | Always active (ambient)        | Company policy           |

---

## How They Compose

- An **agent** (e.g., `@backend-dev`) defines *who* does the work and *how* they approach it.
- A **skill** (e.g., `backend-dev/`) provides *templates and knowledge* the agent draws from.
- An **instruction** (e.g., `backend.instructions.md`) enforces *standards* that apply regardless of who's working.

**Example:** When you invoke `@backend-dev`, it uses its paired `backend-dev` skill for
templates and follows `backend.instructions.md` + `development.instructions.md` +
`governance.instructions.md` for standards.

```
┌─────────────────────────────────────────────┐
│  User: @backend-dev build a REST API        │
├─────────────────────────────────────────────┤
│                                             │
│  Agent ─── backend-dev.agent.md             │
│    ├── Skill ─── skills/backend-dev/        │
│    │     ├── api-spec-template.md           │
│    │     ├── service-template.md            │
│    │     └── error-catalog-template.md      │
│    └── Instructions (ambient)               │
│          ├── development.instructions.md    │
│          ├── backend.instructions.md        │
│          └── governance.instructions.md     │
│                                             │
└─────────────────────────────────────────────┘
```

---

## Why Not Just Agents?

Agents alone can't enforce cross-cutting standards. Instructions are **ambient** — they
apply to ALL agents and even raw Copilot chat. Without instructions, every agent would
need to duplicate security rules, naming conventions, and quality gates.

Consider: you have 50 agents. A new security policy drops. With instructions, you update
one file and every agent inherits it. With agents-only, you'd edit 28 files and hope
you didn't miss one.

---

## Why Not Just Instructions?

Instructions are rules, not workflows. They can tell an agent "always validate input"
but they can't guide a multi-step code review, plan a sprint, or design an API schema.

Agents bring **structured workflows** that go beyond "follow these rules":

- Step-by-step processes with decision points
- Output format specifications
- Handoff protocols between agents
- Model selection for cost/quality trade-offs

---

## Why Skills?

Skills bridge the gap between agents (workflow) and instructions (rules) by providing
**reusable knowledge artifacts** — templates, checklists, decision trees.

Key properties of skills:

1. **Shareable** — Multiple agents can reference the same skill. The `manual-test-strategy`
   skill is used by three different agents.
2. **Composable** — An agent can draw from multiple skills in a single session.
3. **Declarative** — Skills are documents, not code. They're easy to audit and version.

Without skills, templates would live inside agent definitions (bloating them) or in
instructions (mixing policy with reference material).

---

## The Router: Tying It Together

The `/basecoat` router skill sits on top, providing a **single entry point**. Users
don't need to know about the three primitives — they just say:

```
/basecoat backend build a REST API
```

and the router loads the right agent, skill, and instructions automatically.

Two modes:

| Mode        | Example                              | What happens                        |
|-------------|--------------------------------------|-------------------------------------|
| **Discover**| `/basecoat`                          | Shows categorized agent catalog     |
| **Delegate**| `/basecoat backend build a REST API` | Routes to `@backend-dev` with prompt |

The router reads `basecoat-metadata.json` to resolve discipline keywords to agents,
attach paired skills, and validate that instructions exist — all before the agent
sees its first token.

---

## Summary

| Question                          | Answer              |
|-----------------------------------|---------------------|
| Who does the work?                | **Agent**           |
| What knowledge do they use?       | **Skill**           |
| What rules must everyone follow?  | **Instruction**     |
| How does the user access it all?  | **`/basecoat` router** |

Three primitives. One router. Zero ambiguity about where to put things.
