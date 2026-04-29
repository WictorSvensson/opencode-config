---
name: jfrog-artifactory
description: Look up JFrog Artifactory documentation for questions about repositories, package management, NuGet feeds, release bundles, JFrog CLI, and Artifactory configuration. Use this skill when the user asks about Artifactory setup, repos, artifact management, CLI commands, or the JFrog platform.
---

# JFrog Artifactory Documentation

## When to use this skill

Load this skill whenever the user asks about:

- Artifactory repositories (local, remote, virtual, federated)
- Package management (NuGet, npm, Docker, Maven, PyPI, etc.)
- The JFrog CLI (`jf` commands)
- Release bundles and distribution
- Artifact search, properties, or AQL
- Authentication (tokens, API keys, OIDC)
- The HIAB JFrog instance (`hiab.jfrog.io`)
- `nuget.config` setup pointing to Artifactory
- Any other JFrog platform topic

## HIAB instance context

This project uses JFrog Artifactory at `hiab.jfrog.io`.

The NuGet feed is configured in `nuget.config`:

```xml
<add key="jfrog" value="https://hiab.jfrog.io/artifactory/api/nuget/v3/lchicommand-nuget-virtual/index.json" />
```

This is a **virtual NuGet repository** (`lchicommand-nuget-virtual`) served via the Artifactory NuGet v3 API.

---

## Workflow

When the user asks a question about Artifactory:

### Step 1 — Identify the topic

Map the question to a docs section using the reference table below.

### Step 2 — Fetch the relevant docs page

Use WebFetch to retrieve the page. All docs live under:

```
https://docs.jfrog.com/artifactory/docs/<slug>
```

Fetch the specific page for the topic — do **not** rely on training data alone, as JFrog docs change frequently.

### Step 3 — Answer from the fetched content

Base your answer on what the docs say. If the page links to sub-pages relevant to the question, fetch those too.

---

## Key docs reference

| Topic | URL |
|---|---|
| Getting started / overview | `https://docs.jfrog.com/artifactory/docs/getting-started` |
| Artifactory overview | `https://docs.jfrog.com/artifactory/docs/jfrog-artifactory` |
| Repository management overview | `https://docs.jfrog.com/artifactory/docs/repository-management-overview` |
| Local repositories | `https://docs.jfrog.com/artifactory/docs/local-repositories` |
| Remote repositories | `https://docs.jfrog.com/artifactory/docs/remote-repositories` |
| Virtual repositories | `https://docs.jfrog.com/artifactory/docs/virtual-repositories` |
| Federated repositories | `https://docs.jfrog.com/artifactory/docs/federated-repositories` |
| NuGet repositories | `https://docs.jfrog.com/artifactory/docs/nuget-repositories` |
| npm repositories | `https://docs.jfrog.com/artifactory/docs/npm-repositories` |
| Docker repositories | `https://docs.jfrog.com/artifactory/docs/docker-repositories` |
| Maven repositories | `https://docs.jfrog.com/artifactory/docs/maven-repositories` |
| PyPI repositories | `https://docs.jfrog.com/artifactory/docs/pypi-repositories` |
| Supported package types (full list) | `https://docs.jfrog.com/artifactory/docs/supported-package-types` |
| Connect package manager / Set Me Up | `https://docs.jfrog.com/artifactory/docs/use-artifactory-set-me-up-for-configuring-package-manager-clients` |
| Upload and download packages | `https://docs.jfrog.com/artifactory/docs/upload-and-download-packages-using-artifactory` |
| Artifact management | `https://docs.jfrog.com/artifactory/docs/artifact-management` |
| JFrog Properties | `https://docs.jfrog.com/artifactory/docs/jfrog-properties` |
| Artifactory Query Language (AQL) | `https://docs.jfrog.com/artifactory/docs/artifactory-query-language` |
| Search methods | `https://docs.jfrog.com/artifactory/docs/supported-search-methods` |
| JFrog CLI — binary management | `https://docs.jfrog.com/artifactory/docs/binaries-management-with-jfrog-artifactory` |
| JFrog CLI — authentication | `https://docs.jfrog.com/artifactory/docs/authentication` |
| JFrog CLI — generic file operations | `https://docs.jfrog.com/artifactory/docs/generic-files` |
| JFrog CLI — NuGet (`jf nuget` / `jf dotnet`) | `https://docs.jfrog.com/artifactory/docs/jf-dotnet` |
| JFrog CLI — npm | `https://docs.jfrog.com/artifactory/docs/jf-npm` |
| JFrog CLI — Docker | `https://docs.jfrog.com/artifactory/docs/jf-docker` |
| JFrog CLI — Maven | `https://docs.jfrog.com/artifactory/docs/jf-mvn` |
| JFrog CLI — build integration | `https://docs.jfrog.com/artifactory/docs/build-integration` |
| Release bundles (v1) | `https://docs.jfrog.com/artifactory/docs/distribute-release-bundles-v1` |
| Create release bundle (v1) | `https://docs.jfrog.com/artifactory/docs/create-release-bundles-v1` |
| Repository replication | `https://docs.jfrog.com/artifactory/docs/repository-replication` |
| API reference (REST) | `https://docs.jfrog.com/artifactory/reference` |
