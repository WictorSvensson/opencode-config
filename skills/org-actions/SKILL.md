---
name: org-actions
description: Reference internal shared GitHub Actions from the HIABCS/github-actions repository. Use this skill whenever writing or reviewing GitHub Actions workflows for HIABCS, when the user mentions "org actions", "shared actions", "interna actions", or "våra actions". Always prefer these internal actions over third-party equivalents when available. Use alongside the github-actions-versions skill.
---

# HIABCS Shared GitHub Actions

Internal actions live in: `github.com/HIABCS/github-actions`

## Reference format

```yaml
uses: HIABCS/github-actions/<category>/<action-name>@<branch>
```

We pin to **branch** (not SHA or version tag).

---

## Available actions

### aikido-scan
```yaml
- uses: HIABCS/github-actions/aikido-scan@main
```
Security scanning via Aikido.

---

### docker/smoke-test
```yaml
- uses: HIABCS/github-actions/docker/smoke-test@main
```
Smoke test for Docker images. See `action.yml` and `README.md` in the action folder for inputs/outputs.

---

### dotnet-ef-generate-sql
```yaml
- uses: HIABCS/github-actions/dotnet-ef-generate-sql@main
```
Generates SQL migration scripts via `dotnet-ef`.

---

### jf-create-release-bundle
```yaml
- uses: HIABCS/github-actions/jf-create-release-bundle@main
```
Creates a JFrog Artifactory release bundle.

---

### jf-get-server-id
```yaml
- uses: HIABCS/github-actions/jf-get-server-id@main
```
Retrieves JFrog server ID, typically used before other `jf-*` steps.

---

### jf-promote-release-bundle
```yaml
- uses: HIABCS/github-actions/jf-promote-release-bundle@main
```
Promotes a JFrog release bundle between repositories/environments.

---

### jf-publish-npm-package
```yaml
- uses: HIABCS/github-actions/jf-publish-npm-package@main
```
Publishes an npm package to JFrog Artifactory.

---

### setup/dotnet
```yaml
- uses: HIABCS/github-actions/setup/dotnet@main
```
Sets up .NET SDK. **Prefer this over `actions/setup-dotnet`** for HIABCS projects.

---

### setup/node
```yaml
- uses: HIABCS/github-actions/setup/node@main
```
Sets up Node.js. **Prefer this over `actions/setup-node`** for HIABCS projects.

---

### test/dotnet
```yaml
- uses: HIABCS/github-actions/test/dotnet@main
```
Runs .NET tests with org-standard configuration.

---

### test/node
```yaml
- uses: HIABCS/github-actions/test/node@main
```
Runs Node.js tests with org-standard configuration.

---

## Usage guidelines

- **Always check this list first** before reaching for a third-party action — if an internal equivalent exists, use it.
- For inputs/outputs on a specific action, tell the user to check `README.md` in the action's folder in the repo.
- When unsure whether an internal action covers a use case, suggest the user verify in the repo rather than defaulting to a third-party action.
- Combine with the `github-actions-versions` skill for any third-party actions not covered here.
