# Conventions Index

The conventions in this directory define how development on CypherOS is done — not just what to build, but how to build it consistently.

---

| Convention                 | File                                                            | Summary                                                                                                                        |
| -------------------------- | --------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| Documentation              | [`documentation.md`](documentation.md)                          | Where things go in the docs tree, how documents are structured                                                                 |
| Naming                     | [`naming.md`](naming.md)                                        | File names, option names, commit message format                                                                                |
| Git Workflow               | [`git_workflow.md`](git_workflow.md)                            | Branch strategy, commit conventions, PR flow                                                                                   |
| Session Workflow           | [`session_workflow.md`](session_workflow.md)                    | Start-of-session and end-of-session checklist                                                                                  |
| Diagrams                   | [`diagrams.md`](diagrams.md)                                    | Mermaid diagramming standards and diagram type guide                                                                           |
| Templates                  | [`templates.md`](templates.md)                                  | When and how to use the document templates                                                                                     |
| Constants                  | [`constants`](./constants.md)                                   | Working with Constants within the code base; I.e., instead of hard coding them.                                                |
| Gating And Assertions      | [`gating_and_assertions`](./gating_and_assertions.md)           | How to gate logic and enforce the gates via assertions.                                                                        |
| Profile Defaults           | [`profile_defaults`](./profile_defaults.md)                     | Working with profile management and cross-context configuration concerns.                                                      |
| Shared Config Accumulation | [`shared_config_accumulation`](./shared_config_accumulation.md) | internal accumulator options for multi-leaf generated content (e.g. VSCode extension leaves contributing to one settings.json) |

---
