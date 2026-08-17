# Forge contributor guidance

## Scope and module boundaries

- Read the repository `README.md` before proposing or implementing module-level features, public APIs, or architectural changes. Treat it as the source of truth for Forge's products, responsibilities, and dependency boundaries.
- Forge is an app-agnostic Swift package. Do not add Foundry-specific models, branding, screens, endpoints, or design tokens here.
- Keep generic utilities, concurrency helpers, encoding/decoding helpers, and logging abstractions in `ForgeCore`.
- Keep HTTP transport, request construction, authentication integration, uploads, and network errors in `ForgeNetworking`.
- Keep persistence abstractions and storage helpers in `ForgePersistence`.
- Keep reusable, application-agnostic SwiftUI navigation, layout, transition, gradient, and view helpers in `ForgeUI`.
- Maintain one-way dependencies: feature modules may depend on `ForgeCore`; `ForgeCore` must not depend on the other Forge modules.

## Swift and iOS

- Use Swift 6 language and concurrency checking. Prefer `async`/`await`, structured concurrency, and `Sendable` APIs where appropriate.
- Keep public APIs small, explicit, documented when non-obvious, and source-compatible whenever practical.
- Prefer value types and narrow protocols. Do not expose an abstraction unless it has a clear caller or testing need.
- Avoid force unwraps, force casts, and `try!` in production code. Preserve typed errors and cancellation behavior.
- Do not introduce global mutable state or broad actor isolation without a demonstrated need.
- Use platform APIs and existing package utilities before adding dependencies or parallel abstractions.

## Public API and compatibility

- Treat public products and symbols as library API. Avoid breaking renames, removals, or behavior changes without an explicit migration plan.
- Keep app-specific endpoint definitions, credential storage, persistence models, and UI design systems in consuming applications.
- Ensure module imports and product names stay aligned with `Package.swift` when adding or renaming targets.

## Dependencies and package management

- Do not edit `Package.resolved`, `.swiftpm/`, or `.build/` by hand.
- Add an external dependency only when it provides material value that cannot be covered by platform APIs or current Forge modules; ask before adding one.
- Preserve the package's declared iOS and macOS deployment targets unless a version-policy change is explicitly requested.

## Validation and changes

- Add or update focused tests alongside the changed target under `Tests/`.
- Run `swift test` for relevant changes; at minimum run `swift build` or the narrowest applicable test target before handoff.
- **A green build says nothing about lint.** Forge is a pure SwiftPM package with no Xcode project, so there is no build phase to lint from, and no SwiftLint plugin is attached to the targets on purpose — a build tool plugin would push a build dependency onto every consumer of the package. Nothing lints during `swift build`; the pre-commit hook is the only gate. Run its verdict yourself before handoff rather than discovering it when a commit is rejected:
  - `SWIFTLINT_STRICT=1 Scripts/swiftlint.sh`

  Most rules in `.swiftlint.yml` declare only a `warning:` threshold (`line_length` among them), and `--strict` promotes every one of them to an error — exactly what the hook does. A few (`force_unwrapping`, `force_try`, `force_cast`) are errors outright. The severity split is deliberate: warnings must not block compiling mid-edit, and must not survive into a commit, so fix the violation rather than relaxing the rule to match. Only `Sources` is linted; the test targets are deliberately excluded.
- Install the hook once per clone with `Scripts/install-git-hooks.sh`, which points `core.hooksPath` at `Scripts/git-hooks`. The hook autocorrects first, then refuses the commit if autocorrect changed anything, so a rewrite lands in a diff the author reviews and stages instead of being committed silently.
- `Scripts/swiftlint.sh` runs standalone from a bare shell: it takes the project root from `git rev-parse --show-toplevel` and resolves the SwiftLint binary from an Xcode-pinned `SwiftLintBinary.artifactbundle` in DerivedData first — keeping the version aligned with the consuming app — falling back to whatever is on `PATH`. It honours `SWIFTLINT_AUTOCORRECT`, `SWIFTLINT_STRICT`, and `SWIFTLINT_COLOR`.
- Keep tests deterministic and avoid network calls, clock-dependent behavior, or shared mutable state.
- Keep diffs focused; do not reformat unrelated files or overwrite user changes.
- Ask before destructive actions, broad refactors, dependency upgrades, or external side effects.
