---
name: github-actions-versions
description: Look up the latest versions of GitHub Actions before writing or reviewing workflow files. Use this skill whenever the user asks to create, update, fix, or review a GitHub Actions workflow (.yml/.yaml), or whenever any GitHub Action is referenced (e.g. actions/checkout, docker/build-push-action, actions/setup-node). Always trigger this skill before writing any `uses:` line in a workflow — never guess or use a potentially outdated version from memory.
---

# GitHub Actions – Latest Versions

## When to use this skill

Trigger this skill **before writing any GitHub Actions workflow** or when asked to update/review one. Your training data is likely outdated — action versions change frequently and using old versions can cause deprecation warnings, broken pipelines, or security issues.

## Workflow

### Step 1 – Identify all actions needed

Before searching, list every action that will appear in the workflow. Common ones:

- `actions/checkout`
- `actions/setup-node`, `actions/setup-python`, `actions/setup-java`, `actions/setup-go`
- `actions/cache`
- `actions/upload-artifact`, `actions/download-artifact`
- `docker/login-action`, `docker/build-push-action`, `docker/metadata-action`
- `github/codeql-action/*`
- Any third-party actions the user mentions

### Step 2 – Search for latest versions

For **each action**, run a web search using the pattern:

```
latest release <owner>/<action-name> github
```

Examples:
- `latest release actions/checkout github`
- `latest release docker/build-push-action github`

Alternatively, search the GitHub releases page directly:
```
site:github.com/<owner>/<repo>/releases
```

Or fetch the releases API page:
```
https://github.com/<owner>/<repo>/releases/latest
```

> **Always search — never rely on memory.** Even if you're confident about a version, verify it. Versions like `v3`, `v4` may have been superseded.

### Step 3 – Use the correct version pin format

GitHub Actions best practice:

| Format | Example | Use when |
|--------|---------|----------|
| SHA pin + tag comment | `actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # v4.2.2` | **Default for all third-party actions** — SHA is immutable, tag comment preserves readability |
| Major version tag | `actions/checkout@v4` | Only for first-party `actions/*` in low-security contexts where auto-updates are acceptable |
| Exact tag | `actions/checkout@v4.1.2` | When you need reproducibility without SHA verbosity |

**Default to SHA pinning** for all third-party actions (anything not under the `actions/` owner). Version tags are mutable — an upstream maintainer can silently change what `@v4` points to, which is a supply-chain attack vector.

Format for SHA-pinned actions:
```yaml
# Preferred: SHA pin with tag as a human-readable comment
- uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # v4.2.2
```

For first-party `actions/*` actions, major version tags (`@v4`) are acceptable since GitHub controls the namespace and rotates SHAs transparently via their own release process. If in doubt, SHA-pin everything.

### Step 4 – Write the workflow

Now write the workflow using the verified versions. Example structure:

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4          # verified latest
      - uses: actions/setup-node@v4        # verified latest
        with:
          node-version: '20'
```

## Important reminders

- **Never write a `uses:` line without first verifying the version** via web search.
- If a search returns no clear result, note it explicitly and ask the user to verify.
- When updating an existing workflow, check **every** action in it, not just the ones being changed.
- `actions/*` (official GitHub actions) and third-party actions (e.g. `docker/*`, `aws-actions/*`) must both be verified — they follow independent release cycles.
