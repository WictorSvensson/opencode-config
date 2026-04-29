---
name: teamcity-kotlin-dsl
description: Reference for TeamCity Kotlin DSL configuration, HIABCS shared build templates, and JFrog Artifactory integration patterns. Use this skill whenever writing, reviewing, or troubleshooting TeamCity build configurations in Kotlin DSL. Always load this skill before writing any BuildType, Template, VcsRoot, or Project DSL block.
---

# TeamCity Kotlin DSL – HIABCS Reference

## When to use this skill

Load this skill **before writing any TeamCity Kotlin DSL**. Use it to:

- Look up shared templates from `HIABCS/teamcity-actions` before writing custom `BuildType`s
- Verify correct DSL patterns for builds, chains, triggers, and features
- Reference org-standard conventions for parameters, artifact rules, and VCS configuration
- Find the authoritative JFrog Artifactory integration patterns for TeamCity

---

## Org context

- **TeamCity server**: `https://teamcity.hiabcs.internal` *(replace with actual URL)*
- **Shared templates repo**: `https://github.com/HIABCS/teamcity-actions`
- **JFrog instance**: `hiab.jfrog.io`
- **DSL location in projects**: `.teamcity/` folder at repo root, versioned in VCS

---

## Shared build templates

Shared templates live in `HIABCS/teamcity-actions`. **Always check this list first** before writing a custom `BuildType` or `Template` — if an org template covers the use case, use it.

### Reference format

Templates are applied in Kotlin DSL via the `template()` reference on a `BuildType`:

```kotlin
object MyBuild : BuildType({
    templates(MySharedTemplate)
    // ...
})
```

Or imported as an external template from the shared project:

```kotlin
// Reference a template defined in the root/shared project
template(AbsoluteId("SharedProject_TemplateName"))
```

---

### Available shared templates

> ⚠️ **Shared templates table is not yet populated.**
> The `HIABCS/teamcity-actions` repository is private and has not been inventoried here yet.
> **Do not assume any shared template exists.** Fall back to writing custom `BuildType`s and
> note in your output that template coverage should be verified with the platform team against
> `https://github.com/HIABCS/teamcity-actions` before the configuration is committed.
>
> Once the repo has been reviewed, populate this table following the format below and remove this warning.

| Template name | DSL reference | Description |
|---|---|---|
| *(TODO)* | `AbsoluteId("SharedProject_TODO")` | *(TODO: describe what this template provides)* |

**How to add a new entry:**
1. Find the template in `HIABCS/teamcity-actions`
2. Note the `id` declared in the template's `Template({ id("...") })` block
3. Add a row to this table
4. Update the description with what steps/features/parameters it provides

---

## Kotlin DSL patterns

### Project structure

```kotlin
// .teamcity/settings.kts
import jetbrains.buildServer.configs.kotlin.*

version = "2024.03"  // Must match your TeamCity server version

project {
    buildType(Build)
    buildType(Deploy)

    sequential {
        buildType(Build)
        buildType(Deploy)
    }
}
```

> **Important**: The `version` field must match your TeamCity server's DSL API version.
> Check the server version at `https://teamcity.hiabcs.internal` and keep this in sync.
> Mismatches cause DSL compilation warnings and potential behaviour changes.

---

### BuildType skeleton

```kotlin
object Build : BuildType({
    id("MyProject_Build")
    name = "Build"
    description = "Compiles and tests the application"

    // Always set a timeout
    executionTimeoutMin = 30

    vcs {
        root(DslContext.settingsRoot)
        cleanCheckout = false
    }

    steps {
        // steps here
    }

    triggers {
        vcs {
            branchFilter = "+:*\n-:pull/*"
        }
    }

    features {
        perfmon {}  // performance monitoring — include by default
    }

    params {
        // parameters here
    }

    artifactRules = """
        **/build/libs/*.jar => artifacts
        **/test-results/**/*.xml => test-results
    """.trimIndent()

    requirements {
        // agent requirements here
    }
})
```

---

### Build chains (snapshot dependencies)

```kotlin
// Sequential chain
project {
    sequential {
        buildType(Build)
        buildType(Test)
        buildType(Deploy)
    }
}

// Parallel fan-out then join
project {
    sequential {
        buildType(Build)
        parallel {
            buildType(TestUnit)
            buildType(TestIntegration)
            buildType(Lint)
        }
        buildType(Deploy)
    }
}

// Manual snapshot dependency
object Deploy : BuildType({
    dependencies {
        snapshot(Build) {
            onDependencyFailure = FailureAction.FAIL_TO_START
            onDependencyCancel = FailureAction.CANCEL
        }
    }
})
```

---

### VCS roots

```kotlin
object MainVcsRoot : GitVcsRoot({
    id("MyProject_MainVcsRoot")
    name = "Main repository"
    url = "https://github.com/HIABCS/my-repo.git"
    branch = "refs/heads/main"
    branchSpec = "+:refs/heads/*\n+:refs/pull/*/head"

    // Always use token-based auth — never username/password
    authMethod = token {
        userName = "oauth2"
        tokenId = "tc_token_id:my-github-token"  // stored as TeamCity token, not plaintext
    }
})
```

---

### Parameters

```kotlin
params {
    // String parameter
    param("env.APP_ENV", "production")

    // Password parameter — NEVER use param() for secrets
    password("env.API_KEY", "credentialsJSON:my-credential-id")

    // Enum/select parameter with allowed values
    select("deploy.environment", "staging", label = "Target environment",
        options = listOf("staging" to "Staging", "production" to "Production")
    )

    // Read-only display parameter
    param("build.version", "%build.counter%")
}
```

> 🔴 **Security rule**: Never put secret values inline. Always use `password()` with
> `credentialsJSON:<id>` references or TeamCity Tokens. Plain `param()` values are
> visible in the UI and build logs.

---

### Build features

```kotlin
features {
    // Pull request support (GitHub)
    pullRequests {
        vcsRootExtId = "${MainVcsRoot.id}"
        provider = github {
            authType = token {
                token = "credentialsJSON:github-token"
            }
            filterAuthorRole = PullRequests.GitHubRoleFilter.MEMBER
        }
    }

    // Commit status publisher
    commitStatusPublisher {
        vcsRootExtId = "${MainVcsRoot.id}"
        publisher = github {
            githubUrl = "https://api.github.com"
            authType = personalToken {
                token = "credentialsJSON:github-token"
            }
        }
    }

    // Docker support (if using Docker build runner)
    dockerSupport {
        cleanupPushedImages = true
    }
}
```

---

### Templates

```kotlin
object CiTemplate : Template({
    id("SharedProject_CiTemplate")
    name = "CI Template"

    executionTimeoutMin = 60

    features {
        perfmon {}
        pullRequests { /* ... */ }
        commitStatusPublisher { /* ... */ }
    }

    triggers {
        vcs {
            branchFilter = "+:*\n-:pull/*"
        }
    }
})

// Apply in a BuildType:
object MyBuild : BuildType({
    templates(CiTemplate)
    name = "My Build"
    // Override or extend template settings here
})
```

---

## JFrog Artifactory integration

When a build publishes artifacts to or resolves dependencies from JFrog Artifactory at `hiab.jfrog.io`, load the `jfrog-artifactory` skill for full context. Common patterns:

### Dependency resolution via Artifactory (Maven/Gradle)

```kotlin
steps {
    maven {
        goals = "clean package"
        // Point settings.xml at Artifactory virtual repo
        // Use TeamCity Artifactory plugin build runner for build info
        runnerArgs = "-s %system.teamcity.build.checkoutDir%/settings.xml"
    }
}
```

### Publishing via JFrog CLI

```kotlin
steps {
    script {
        name = "Publish to Artifactory"
        scriptContent = """
            jf rt u "build/libs/*.jar" "hiabcs-libs-release-local/" \
              --build-name="%teamcity.buildType.id%" \
              --build-number="%build.number%" \
              --url=https://hiab.jfrog.io/artifactory \
              --access-token="%env.JF_ACCESS_TOKEN%"
            jf rt bp "%teamcity.buildType.id%" "%build.number%"
        """.trimIndent()
    }
}

params {
    // Access token must ALWAYS be a password parameter
    password("env.JF_ACCESS_TOKEN", "credentialsJSON:jfrog-access-token")
}
```

> Always use **virtual repositories** (not local/remote directly) for both resolution
> and publishing targets. For HIAB the NuGet virtual repo is `lchicommand-nuget-virtual`.
> Confirm other virtual repo names with the platform team or the JFrog skill.

---

## Docs lookup workflow

When the built-in patterns above don't cover a DSL API you need, fetch the official docs:

### Step 1 — Identify the DSL class or concept

Examples: `BuildType`, `GitVcsRoot`, `ArtifactDependency`, `Schedule` trigger, `DockerSupport` feature

### Step 2 — Fetch the relevant docs page

```
https://www.jetbrains.com/help/teamcity/kotlin-dsl.html
https://www.jetbrains.com/help/teamcity/<concept-slug>.html
```

Or fetch the generated DSL API docs for your server version directly:

```
https://teamcity.hiabcs.internal/app/dsl-documentation/index.html
```

> The server-local DSL docs at `/app/dsl-documentation/` always match your exact
> TeamCity version and are the most authoritative source. Prefer them over generic
> JetBrains docs when there's any ambiguity.

### Step 3 — Answer from fetched content

Base your DSL on what the docs say. If a page links to sub-pages relevant to the question, fetch those too. Never rely on training data alone for DSL API details — TeamCity DSL evolves with each server version.

---

## Usage guidelines

- **Always check the shared templates table first** before writing a custom `BuildType` — if an org template covers the use case, use it.
- **Always set `executionTimeoutMin`** on every `BuildType` — no build should run indefinitely.
- **Never use `param()` for secrets** — use `password()` with `credentialsJSON:` references.
- **Always use token-based VCS auth** — never store username/password in DSL.
- **Load `jfrog-artifactory` skill** whenever the task involves publishing artifacts, resolving from Artifactory, or creating release bundles.
- **Verify DSL version compatibility** — the `version` in `settings.kts` must match the TC server version.
- When unsure whether an org template covers a use case, tell the user to verify in `HIABCS/teamcity-actions` rather than defaulting to a custom build type.
