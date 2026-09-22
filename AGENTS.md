# Forge contributor guidance

## Forge is shared

- Forge is an app-agnostic Swift package used by Foundry and by other projects. Nothing in it may name a consuming app's concept — its models, branding, screens, endpoints, credentials, or design tokens. Those stay in the app.
- Consumers depend on `branch: "main"` and Forge has no tagged releases, so **every push to `main` ships to every consumer** the next time it re-resolves. That is why:
  - **Never commit or push without the user's explicit go-ahead, every time.** There is no standing approval. Make the change, then stop and ask.
  - **Ask before starting any non-trivial source change**, not only before committing it. Avoid broad or speculative changes; take Forge work on only when it is genuinely needed.
  - Ask before destructive actions, broad refactors, dependency upgrades, or external side effects.
- When Forge is checked out beside Foundry, the workspace `CLAUDE.md` above both covers working across the two: waiting for the user to re-resolve Foundry's packages after a Forge push, and never bumping Foundry's pinned Forge revision as a side effect.

## Public API

- Treat every `public` symbol as library API. Keep it small and explicit, and do not expose an abstraction unless it has a clear caller or testing need.
- **A breaking change to a public API needs the user's approval before work starts.** A rename, a removal, a changed signature, or a behaviour change a caller could depend on is breaking. Once approved, make it a clean break: change it, delete the old spelling, and add no deprecation shim. Name the break and its replacement in the commit message, since that is what other consumers read when their build fails after re-resolving. Update Foundry's callers in a follow-up, once the user has re-resolved.
- Within Forge, when a shared API changes, update every caller in the same change and delete the old spelling.

## Module boundaries

The README's product table is the map of what each module holds. The rules:

- `ForgeCore` holds general-purpose utilities: extensions, concurrency, coding, logging, validation, and state types. It depends on no other Forge module. It may import SwiftUI for observable state and validation types that views consume, such as `AsyncState` and `FormFieldState`, but views, view modifiers, and components belong in `ForgeUI`.
- `ForgeNetworking` holds HTTP transport, request construction, authentication integration, uploads, and network errors. Depends on `ForgeCore`.
- `ForgePersistence` holds SwiftData and `UserDefaults` infrastructure. Depends on `ForgeCore`.
- `ForgeUI` holds app-agnostic SwiftUI navigation, layout, components, modifiers, and transitions, without imposing a design system. Depends on `ForgeCore` and `ForgePersistence`.
- Dependencies point only the way listed. Keep `Package.swift` product, target, source-folder, and import names aligned when adding or renaming a module.

## Swift

- Swift 6 language mode, with the `ApproachableConcurrency` upcoming feature enabled on every target; enable it on a new target too. Prefer `async`/`await`, structured concurrency, and `Sendable` APIs.
- Do not introduce global mutable state or broad actor isolation without a demonstrated need. Preserve typed errors and cancellation behaviour.
- Prefer value types and narrow protocols. A stateless helper that needs configuration (a `Calendar`, a date provider) is a `struct` taking it once at `init`, not an enum of static methods.
- Force-unwrap only a value that is guaranteed to exist and be valid, and write it as ForgeCore's `.forceUnwrap`, never `!` — SwiftLint rejects `!`, and `.forceUnwrap` still traps on nil in release builds. Handle anything that can legitimately be absent. `try!` and `as!` are lint errors.
- Capture `unowned` rather than `weak` in a closure when the reference is guaranteed to outlive it and `weak` would only add unwrapping noise.
- Use platform APIs and existing Forge utilities before adding a dependency or a parallel abstraction.
- Use `Dino Catalinac` as the author in file headers for new files. Never attribute files to an assistant. Code taken from another project keeps its original license header.

## Documentation

- Keep doc comments to a sentence or two: the decision and the one reason it matters. Document a public API by its purpose and usage, not its implementation. Include history only when someone would otherwise undo the decision.
- Per-API usage belongs in the symbol's doc comment. The README lists what ships: add a line when adding a feature area and remove it when removing one. Reference material for one module sits beside its code, as [`Sources/ForgeNetworking/README.md`](Sources/ForgeNetworking/README.md) does; list such a file in its target's `exclude:`, or SwiftPM warns about it in every consumer's build.

## SwiftUI

- Give every standalone public component and view modifier in `ForgeUI` at least one representative `#Preview`.
- Do not comment how a view is laid out. Document the contract of anything reusable — components, view modifiers, and the action types that form their API — by its purpose and usage.
- A component with no-argument `@ViewBuilder` content builds it once in `init` and stores the resulting view, not the closure. SwiftUI can compare stored views but not closures, so a stored closure re-runs on every parent update. Closures that take arguments, and action closures, stay closures.

## Dependencies and package management

- Do not edit `Package.resolved`, `.swiftpm/`, or `.build/` by hand. The shared schemes under `.swiftpm/xcode/xcshareddata/xcschemes/` are tracked and written by Xcode.
- Add an external dependency only when it provides value that platform APIs and Forge cannot, and ask first — every consumer inherits it.
- Declare every module a target imports as a dependency of that target, even when it already arrives transitively.
- Preserve the declared iOS and macOS deployment targets unless a version-policy change is requested.
- A "cannot find type in scope" error for a type that exists usually means SwiftPM cached a stale source list: run `swift package clean`.

## Validation

- Run `swift test` from the repository root. It is sufficient; do not add iOS simulator runs on top of it.
- Lint is not part of a green build: nothing lints during `swift build`, and the pre-commit hook is the only gate. Run its verdict before handing off: `SWIFTLINT_STRICT=1 Scripts/swiftlint.sh`. Fix the violation rather than changing a rule's severity. [`Scripts/README.md`](Scripts/README.md) explains the scripts and why there is no lint plugin.
- Do not distort code or architecture merely to satisfy SwiftLint. If the proper fix is unclear, ask; prefer a narrow, documented suppression when the rule does not improve that specific code.
- Install the git hooks once after cloning: `Scripts/install-git-hooks.sh`. The hook autocorrects, then stops the commit if autocorrect changed a file, leaving the rewrite to review and stage.

## Tests

- Behavioural changes need focused tests in the `Tests/` target matching the changed module. Write them after the implementation has been approved, since a design that changes on review would mean rewriting them.
- **Test code never needs the user's review or approval.** Write, update, and fix tests without asking, including failing ones. Only implementation code is reviewed; if a test requires changing implementation code, that change needs review.
- Keep tests deterministic: no network calls, no dependence on the real clock (inject a `DateProvider`), and no shared mutable state.
- Derive expectations from the constant under test rather than hardcoding a value that duplicates it. Avoid locale-specific characters in assertions on formatted strings; prefer `hasPrefix`/`hasSuffix` or similar.

## Changes and commits

- **A requested plan is a document, not a build.** Save it to `.claude/plans/<topic>.md` and stop; approving the plan is not approval to implement it.
- Work in the main checkout, never a git worktree: the user reviews in their own checkout and cannot see a worktree. Use a branch there when work needs isolating.
- Keep diffs small and focused; do not reformat unrelated files, and do not overwrite or discard pre-existing user changes.
- **The index belongs to the user.** They stage files as they review them, and a lost staging area cannot be recovered. Never `git add` changes to existing files, `git reset`, or `git stash`. Every change must still be visible in their diff: stage each new file with a plain `git add <path>` right after creating it (never `git add -N`), delete tracked files with `git rm`, and rename with `git mv`.
- Once a commit is approved, staging is part of committing: check what is already staged with `git diff --cached --name-only`, commit, and confirm what landed with `git show --stat`. Push only when the go-ahead covered pushing.
