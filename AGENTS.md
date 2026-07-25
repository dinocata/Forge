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
- Keep tests deterministic and avoid network calls, clock-dependent behavior, or shared mutable state.
- Keep diffs focused; do not reformat unrelated files or overwrite user changes.
- Ask before destructive actions, broad refactors, dependency upgrades, or external side effects.
