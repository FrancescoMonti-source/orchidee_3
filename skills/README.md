# Repository skills

Selected from [mattpocock/skills](https://github.com/mattpocock/skills), pinned to
commit `49dd158d1076134a641b33efb035946536778336`. The upstream files are unchanged;
`source.json` records their original paths and Git blob hashes. The upstream MIT
license is in `LICENSE`.

## Selected workflows

| Skill | Invocation | Use |
|---|---|---|
| [domain-modeling](domain-modeling/SKILL.md) | User or agent | Sharpen terminology and maintain the domain glossary and decisions. |
| [grill-with-docs](grill-with-docs/SKILL.md) | User | Work through decisions by interview while updating glossary and ADRs. |
| [research](research/SKILL.md) | User or agent | Investigate primary sources and save cited findings. |
| [handoff](handoff/SKILL.md) | User | Prepare context for another session or agent. |
| [wait-what](wait-what/SKILL.md) | User | Re-explain an unclear answer with the missing context. |
| [wayfinder](wayfinder/SKILL.md) | User | Plan and work through a large effort as decision tickets on a shared map. |
| [to-questionnaire](to-questionnaire/SKILL.md) | User | Draft questions for someone holding knowledge the user needs. |
| [retro](retro/SKILL.md) | User | Identify improvements to the agent's working environment after a session. |
| [writing-for-agents](writing-for-agents/SKILL.md) | User or agent | Write or edit skills, steering files and other agent-facing documents. |
| [to-spec](to-spec/SKILL.md) | User | Synthesize the agreed conversation into a specification for the configured issue tracker. |
| [to-tickets](to-tickets/SKILL.md) | User | Split an agreed plan into tickets and their blocking dependencies. |
| [improve-codebase-architecture](improve-codebase-architecture/SKILL.md) | User | Survey architectural friction, show candidates and explore a selected improvement. |
| [tdd](tdd/SKILL.md) | User or agent | Develop tests and implementation through the red-green loop at agreed interfaces. |
| [diagnosing-bugs](diagnosing-bugs/SKILL.md) | User or agent | Reproduce, minimise, diagnose and verify a bug fix. |
| [implement](implement/SKILL.md) | User | Implement a specification or tickets, review the work and commit it. |
| [code-review](code-review/SKILL.md) | User or agent | Review a change against both repository standards and its specification. |

`User` means an explicitly requested workflow. `User or agent` skills may also
be selected when their task matches or reached as helpers by another workflow.
Installing these files does not execute their workflows.

## Required helpers

| Skill | Required by |
|---|---|
| [codebase-design](codebase-design/SKILL.md) | `improve-codebase-architecture`, interface design reached through `tdd` |
| [grilling](grilling/SKILL.md) | `grill-with-docs`, `improve-codebase-architecture`, `wayfinder` |
| [prototype](prototype/SKILL.md) | Prototype tickets reached through `wayfinder` |

Load a helper's `SKILL.md` when the workflow reaches it. Its reference files stay
with the skill. Selected skills can also be reused by other workflows:
`domain-modeling` and `research` support `wayfinder`; `writing-for-agents`
supports `retro`; `implement` uses `tdd` and `code-review`. References to
`setup-matt-pocock-skills` are setup fallbacks; this repository already supplies
its tracker, labels and domain configuration below.

## Repository integration

- **Domain vocabulary:** `CONTEXT.md` is this repository's glossary. In upstream
  skills and their templates, read `GLOSSARY.md` as `CONTEXT.md`. Follow
  `docs/agents/domain.md` and preserve the existing glossary layout, bilingual
  terminology and ADR conventions.
- **Issue tracker:** use `docs/agents/issue-tracker.md` and the label mapping in
  `docs/agents/triage-labels.md`.
- **Skill loading:** when upstream says to call the Skill tool, load the named
  installed skill's `SKILL.md` and follow it using the tools available in this
  session. A request to install a skill only installs it; invoking its workflow
  is a separate task.
- **Invocation:** ask, for example, "Use to-spec for this discussion" or "Use
  wayfinder on this map". In hosts with skill mentions, `$to-spec` is the
  equivalent explicit invocation. Preserve the user-invocation policies in the
  manifests and `agents/openai.yaml` files.

## Discovery and verification

The versioned skill files live here because `.agents/` is ignored by the
repository. Run this command after a fresh checkout:

```bash
python tools/link_agent_skills.py
```

It verifies the upstream files and creates local discovery links under
`.agents/skills/`. Existing unrelated files or links are left in place; a
conflicting skill name is reported rather than overwritten.

```bash
python tools/link_agent_skills.py --check
```

The check verifies source hashes, skill names, explicit-invocation metadata and
discovery links without changing files. Hosted sessions that do not expose these
skills in their catalog can still load them through this guide and the pointer
in `AGENTS.md`.

Updates are manual: import the chosen upstream version with its references,
license and updated `source.json`, then rerun verification. Repository integration
stays in this guide so the upstream copies remain checkable.
