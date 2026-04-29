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

| Template name | DSL reference | Description |
|---|---|---|
| `ConanPublishTemplate` | `AbsoluteId("<YourProjectId>_ConanPublishTemplate")` | Full 11-step Conan C/C++ package publish pipeline: installs Conan + JFrog CLI, creates the package for armv7hf, uploads to Artifactory, and publishes build-info with git metadata. |

**How to add a new entry:**
1. Find the template in `HIABCS/teamcity-actions`
2. Note the `id` declared in the template's `Template({ id("...") })` block
3. Add a row to this table
4. Update the description with what steps/features/parameters it provides

---

## ConanPublishTemplate

Defined in `HIABCS/teamcity-actions/.teamcity/templates/ConanPublishTemplate.kt`.  
Registered in the parent project's `settings.kts` via `template(ConanPublishTemplate)`.

### Pipeline steps (in order)

| # | Step | Description |
|---|---|---|
| 1 | Set PACKAGE_VERSION (git SHA) | Derives version from the first 7 characters of the git SHA. Override this step in the child build for tag-based versioning. |
| 2 | Install tools (Conan + JFrog CLI) | Downloads Conan 2.27.1 and JFrog CLI 2.102.0; propagates both to PATH via a TeamCity service message. |
| 3 | Ensure default Conan profile | Runs `conan profile detect --exist-ok` so ephemeral agents always have a profile. |
| 4 | Configure JFrog CLI server | Registers the JFrog server using `JFROG_URL` and `JFROG_TOKEN`. |
| 5 | Clean stale build-info | Runs `jf rt build-clean` to remove leftover build-info from a previous agent run (`\|\| true` — safe if nothing exists). |
| 6 | Add Conan remote | Registers the Artifactory Conan repository as a Conan remote. |
| 7 | Validate PACKAGE_VERSION | Fails the build immediately with a clear message if the version is still empty. |
| 8 | Download Conan dependencies | Exits immediately with success when `CONAN_DEPENDENCIES` is blank. When populated, downloads each entry using `jf conan install --requires`. |
| 9 | Create Conan package | Runs `jf conan create` targeting armv7hf host architecture. |
| 10 | Upload package | Uploads the package to Artifactory with build-info association. |
| 11 | Publish build-info | Publishes build-info including git metadata. Env vars matching `*password*`, `*secret*`, `*token*`, `*_key*`, `*_access_key*`, or `*conan_password*` are excluded automatically. |

> ⚠️ The template does **not** set `executionTimeoutMin`. Every child `BuildType` that references this template **must** set it explicitly to suit expected build duration.

### Template parameters

| Parameter | Default | Description |
|---|---|---|
| `PACKAGE_NAME` | *(required)* | Conan package name. |
| `CONAN_REPO` | *(required)* | Artifactory Conan repository name. |
| `JFROG_URL` | `https://hiab.jfrog.io` | JFrog Platform base URL — **no** `/artifactory` suffix. |
| `CONAN_SERVER_ID` | `hiab` | JFrog CLI server ID and Conan remote name. |
| `BUILD_NAME` | `%PACKAGE_NAME%` | Build name used for build-info tracking in Artifactory. |
| `PACKAGE_VERSION` | *(set at runtime)* | Resolved in step 1; intentionally blank so downstream steps fail explicitly if step 1 is skipped. |
| `CONAN_DEPENDENCIES` | *(blank)* | Whitespace-separated list of Conan references to download before the build, e.g. `mylib/1.0.0 otherlib/2.3.1`. Full Conan 2.x reference format supported: `name/version@user/channel#revision`. Leave blank to skip all downloads. |

### Requirements

- **Agent OS**: Linux
- **TeamCity version**: 2025.11
- **`JFROG_TOKEN`**: Must be defined at the **TeamCity project level** as an inherited `password()` parameter referencing a stored TeamCity credential. It is intentionally **never** declared in the DSL library so it is never stored in source control.

```kotlin
// In the parent project's settings.kts — NOT in the library
password("JFROG_TOKEN", "credentialsJSON:your-jfrog-credential-id")
```

### Usage — reference from a child build configuration

The absolute ID is formed by combining the parent TeamCity project ID with `ConanPublishTemplate`, separated by an underscore. Replace `<YourProjectId>` with the actual internal project ID shown in your TeamCity project settings.

```kotlin
object PublishMyPackage : BuildType({
    name = "Publish my-package"

    templates(AbsoluteId("<YourProjectId>_ConanPublishTemplate"))

    // Required — always set a timeout; the template does not set one
    executionTimeoutMin = 30

    params {
        param("PACKAGE_NAME", "my-package")
        param("CONAN_REPO",   "my-conan-repo")
    }
})
```

### Usage — `jfrogConanParams()` for standalone build configurations

Use the `jfrogConanParams()` helper (from `params/JfrogParams.kt`) when composing individual step functions rather than inheriting the full template. All three arguments are **required** when calling this helper directly.

> `JFROG_TOKEN` is excluded from this helper — it must be inherited from the project level.

```kotlin
import params.jfrogConanParams

object MyBuildConfig : BuildType({
    executionTimeoutMin = 30

    params {
        jfrogConanParams(
            packageName = "my-package",
            conanRepo   = "my-conan-repo",
            buildName   = "my-package-build"
        )
    }
})
```

### Adding a new pipeline step

Each step is a Kotlin extension function on `BuildSteps` that registers a `script {}` block. Follow this pattern:

1. Create a new file in `.teamcity/steps/`, e.g. `MyStep.kt`.
2. Define the extension function:

```kotlin
package steps

import jetbrains.buildServer.configs.kotlin.BuildSteps
import jetbrains.buildServer.configs.kotlin.buildSteps.script

fun BuildSteps.myStep() {
    script {
        name = "My step"
        scriptContent = """
            #!/usr/bin/env bash
            set -euo pipefail
            echo "Hello from my step"
        """.trimIndent()
    }
}
```

3. Import and call `myStep()` inside the `steps { }` block of `ConanPublishTemplate.kt` (or any other template/build configuration that needs it).

### Repository structure reference

```
teamcity-actions/
└── .teamcity/
    ├── settings.kts                  # Root project — registers ConanPublishTemplate
    ├── pom.xml                       # Maven build descriptor for Kotlin DSL compilation
    ├── templates/
    │   └── ConanPublishTemplate.kt   # Full Conan publish pipeline template
    ├── params/
    │   └── JfrogParams.kt            # jfrogConanParams() extension function
    └── steps/
        ├── InstallTools.kt           # Installs Conan and JFrog CLI, updates PATH
        ├── EnsureConanProfile.kt     # conan profile detect for clean agents
        ├── ConfigureJfrogServer.kt   # Configures JFrog CLI server with token auth
        ├── CleanStaleBuildInfo.kt    # Clears leftover build-info from previous runs
        ├── AddConanRemote.kt         # Registers Artifactory repo as a Conan remote
        ├── ValidatePackageVersion.kt # Fails early if PACKAGE_VERSION is empty
        ├── ConanDownload.kt          # Downloads Conan deps via jf conan install
        ├── ConanCreate.kt            # Cross-compiles package for armv7hf
        ├── ConanUpload.kt            # Uploads package to Artifactory
        └── PublishBuildInfo.kt       # Publishes build-info with git metadata
```

---

## Kotlin DSL patterns

### Project structure

```kotlin
// .teamcity/settings.kts
import jetbrains.buildServer.configs.kotlin.*

version = "2025.11"  // Must match your TeamCity server version

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

When a build publishes artifacts to or resolves dependencies from JFrog Artifactory at `hiab.jfrog.io`, load the `jfrog-artifactory` skill for full context.

> 🔴 **`JFROG_TOKEN` security rule**: Never declare `JFROG_TOKEN` in any DSL library or shared template. It must always be defined at the **TeamCity project level** as a `password()` parameter so it is never stored in source control. Child build configurations and shared templates inherit it automatically.

### Conan C/C++ packages (org standard — use `ConanPublishTemplate`)

For Conan packages, always use `ConanPublishTemplate` from `HIABCS/teamcity-actions` (see section above). Do **not** write a custom build type for Conan publishing.

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
- **For Conan C/C++ publishing**, always use `ConanPublishTemplate` from `HIABCS/teamcity-actions`. Do not write a custom build type.
- **Always set `executionTimeoutMin`** on every `BuildType` — no build should run indefinitely. `ConanPublishTemplate` does not set this; every child build must set it explicitly.
- **Never use `param()` for secrets** — use `password()` with `credentialsJSON:` references.
- **Never declare `JFROG_TOKEN` in a DSL library or shared template** — it must be defined at the project level as a `password()` parameter so it is never stored in source control.
- **Always use token-based VCS auth** — never store username/password in DSL.
- **Load `jfrog-artifactory` skill** whenever the task involves publishing artifacts, resolving from Artifactory, or creating release bundles.
- **Verify DSL version compatibility** — the `version` in `settings.kts` must match the TC server version (`2025.11`).
