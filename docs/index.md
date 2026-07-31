# Documentation Index

This is the root of CypherOS documentation. All project knowledge lives here — _architecture, decisions, development history, incidents, contributing conventions, and templates_.

---

## Structure

```
docs/
├── project/          — what the system is and why it was built this way
│   ├── overview.md   — architecture overview + system diagrams
│   ├── tech-stack.md — technology curation: every tool, why it was chosen
│   ├── decisions/    — Architecture Decision Records (ADRs)
│   └── runbooks/     — operational runbooks
├── development/      — development history and session logs
│   ├── journal/      — per-session development journal entries
│   └── incidents/    — incident records
├── contributing/     — conventions and workflow for working on this repo
└── templates/        — templates for ADRs, incidents, journal entries, RFCs
```

---

## Quick Links

| Resource                 | Path                                                  |
| ------------------------ | ----------------------------------------------------- |
| Architecture Overview    | [docs/project/overview.md](project/overview.md)     |
| Technology Stack         | [docs/project/tech-stack.md](./project/tech-stack.md) |
| Decision Records         | [docs/project/decisions/](./project/decisions/)       |
| Development Journal      | [docs/development/journal/](./development/journal/)   |
| Incidents                | [docs/incidents/](./development/incidents/)           |
| Templates                | [docs/templates/](./templates/)                       |
| Contributing Conventions | [docs/contributing/](./contributing/)                 |

---

## Vision & Roadmap

These live at the repository root:

- [`VISION.md`](../VISION.md) — the design intent, the five pillars, what success looks like
- [`ROADMAP.md`](../ROADMAP.md) — implementation phases and pending work
- [`CHANGELOG.md`](../CHANGELOG.md) — notable changes per version, linked to ADRs and incidents
