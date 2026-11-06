# Spectionflow

Document-driven skills that take a feature from idea to reviewed code with an AI coding agent.
Plain instructions, no runtime, no dependencies.

| Skill | What it does |
|---|---|
| `/inception` | Lightweight inception: pain, customer, value hypothesis and Milestone 1 scope |
| `/analysis` | Pre-proposal study (discovery, capability, decision, strategic, root cause, item) |
| `/proposal` | The feature spec: problem, solution, business rules, acceptance criteria and a phased implementation plan |
| `/implement` | Implements one phase of the proposal |
| `/review` | Reviews a phase (or the whole feature) against the proposal and writes a verdict |
| `/pipeline` | Runs proposal → implement → review per phase → final review, with human checkpoints |

Documentation: [docs/README.md](docs/README.md) — start with [getting started](docs/getting-started.md) and the [workflow overview](docs/WORKFLOW.md).

## Install

Skills are folders with a `SKILL.md` (the Agent Skills format used by Claude Code and compatible agents).

```sh
./install.sh /path/to/your/project        # -> /path/to/your/project/.claude/skills
./install.sh --user                       # -> ~/.claude/skills
./install.sh --dir some/skills/dir        # any agent that reads skills from a folder
./install.sh --only "proposal review"     # a subset
```

Or copy the folders from `skills/` by hand.

## Use

```
/inception init My product idea…
/analysis Notification Retry Strategy
/proposal Notification_Retry
/pipeline Notification_Retry all
```

Artifacts land in `docs/` of your project (`docs/features/<Feature>/…`).

## License

MIT — see [LICENSE](LICENSE).
