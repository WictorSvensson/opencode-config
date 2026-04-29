# opencode-config

Shared [OpenCode](https://opencode.ai) agent team, skills, and plugins for HIABCS development workflows.

## What's included

### Agents

| Agent | Mode | Purpose |
|---|---|---|
| `orchestrator-main` | primary | Coordinates all subagents for non-trivial tasks — start here |
| `github-actions-devops` | subagent | Write, review, and debug GitHub Actions workflows |
| `teamcity-devops` | subagent | Write, review, and debug TeamCity Kotlin DSL pipelines |
| `code-reviewer` | subagent | Code review across all languages and file types |
| `qa-tester` | subagent | Test writing, test execution, and bug reporting |
| `tech-architect` | subagent | Architectural guidance and technology decisions (advisory only) |

### Skills

| Skill | Purpose |
|---|---|
| `github-actions-versions` | Looks up latest GitHub Actions versions before writing any workflow |
| `org-actions` | Registry of HIABCS internal shared actions from `HIABCS/github-actions` |
| `jfrog-artifactory` | JFrog docs lookup for the `hiab.jfrog.io` Artifactory instance |
| `teamcity-kotlin-dsl` | TeamCity Kotlin DSL patterns, shared templates, and JFrog integration |

### Plugin

| Plugin | Purpose |
|---|---|
| `no-commit-push` | Blocks accidental `git commit` and `git push` — all VCS operations must be run manually |

---

## Install

**1. Clone the repo:**

```sh
git clone https://github.com/WictorSvensson/opencode-config.git ~/Develop/opencode-config
```

**2. Run the setup script:**

```sh
~/Develop/opencode-config/setup.sh
```

`setup.sh` symlinks all agents, skills, and the plugin into `~/.config/opencode/`. It never overwrites files you've created yourself — it warns and skips them instead.

Works on macOS and Linux.

---

## Stay up to date

```sh
cd ~/Develop/opencode-config && git pull
```

No need to re-run `link.sh` — symlinks already point into the repo, so a `git pull` is all it takes.

Re-run `setup.sh` only if new agents or skills have been added to the repo since you first installed.

---

## Contributing

1. Edit files directly in `~/.config/opencode-config/` (your local clone)
2. Test your changes by restarting OpenCode
3. Open a PR against `main` in this repo

Since your `~/.config/opencode/` files are symlinks into the clone, changes take effect immediately — no copy step needed.

---

## What this does NOT manage

This repo intentionally does not touch:

- `~/.config/opencode/opencode.json` — personal model/provider config and API keys
- `~/.config/opencode/AGENTS.md` — personal global rules
- MCP server configuration
- Keybinds, themes, or other personal preferences

These remain entirely under your own control.

---

## Notes for new installs

### TeamCity shared templates

The `teamcity-kotlin-dsl` skill has a shared templates table in `skills/teamcity-kotlin-dsl/SKILL.md` that references `HIABCS/teamcity-actions`. This table contains TODO placeholders and **must be populated** before the `teamcity-devops` agent can recommend org-standard templates.

To populate it:
1. Review the templates in `https://github.com/HIABCS/teamcity-actions`
2. Edit `skills/teamcity-kotlin-dsl/SKILL.md` — find the `### Available shared templates` section
3. Add a row per template following the existing format
4. Open a PR so the whole team benefits

### org-actions

The `org-actions` skill (`skills/org-actions/SKILL.md`) lists the shared GitHub Actions from `HIABCS/github-actions`. Keep this in sync when new shared actions are added to that repo.
