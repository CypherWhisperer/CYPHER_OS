# Contributing

Conventions, workflow, and standards for working on the CypherOS repository. The goal of these conventions is that working in this repo feels consistent and predictable — _and eventually, second nature._

---

## Conventions

| Document                                                               | Covers                                                            |
| ---------------------------------------------------------------------- | ----------------------------------------------------------------- |
| [`conventions/documentation.md`](conventions/documentation.md)       | How documentation is structured, where things go, what goes where |
| [`conventions/naming.md`](conventions/naming.md)                     | File naming, option naming, commit message format                 |
| [`conventions/git-workflow.md`](./conventions/git-workflow.md)         | Branch strategy, commit conventions, PR flow                      |
| [`conventions/session-workflow.md`](./conventions/session-workflow.md) | How a development session should start and end                    |
| [`conventions/diagrams.md`](conventions/diagrams.md)                 | Diagramming standards — Mermaid, when to use which diagram type   |
| [`conventions/templates.md`](conventions/templates.md)               | When and how to use each template                                 |
| [`conventions/index.md`](conventions/index.md)                       | Conventions index                                                 |

---

## Quick Reference — Conventions at a Glance

- **Documentation format:** Markdown for everything. Mermaid for all diagrams.
- **Default branch:** `master`
- **Commit format:** Conventional Commits — `type(scope): message`
- **ADR:** Write one for every significant architectural or tooling decision. Write it _before_ implementing where possible.
- **Journal:** One entry per meaningful development session. Informal — honest beats polished.
- **Incident:** One document per incident. Linked from every artifact it affected.
- **Inline comments:** First-class in Nix modules. A well-commented module is self-documenting.
