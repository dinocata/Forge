# Scripts

## Linting

SwiftLint enforces `.swiftlint.yml` over `Sources`; the test targets are deliberately not linted.

Nothing lints during `swift build`. Forge is a pure SwiftPM package with no Xcode project to attach a build phase to, and it deliberately has no SwiftLint build tool plugin: a plugin would add a build dependency to every package that consumes Forge. The pre-commit hook is the only gate, so run its verdict on demand:

```sh
SWIFTLINT_STRICT=1 Scripts/swiftlint.sh
```

Most rules declare only a warning threshold, and strict mode promotes every warning to an error, as the hook does. `force_unwrapping`, `force_try`, and `force_cast` are errors outright. The split is deliberate: warnings should not interrupt an edit-and-build cycle, and should not survive into a commit.

### `swiftlint.sh`

Runs from any directory; it takes the repository root from `git rev-parse --show-toplevel`. It prefers the `SwiftLintBinary.artifactbundle` an Xcode project has already resolved into DerivedData, so a consuming app and Forge lint with the same version, and falls back to `swiftlint` on `PATH`.

| Variable | Effect when set to `1` |
| --- | --- |
| `SWIFTLINT_AUTOCORRECT` | Applies SwiftLint's automatic fixes before validating. |
| `SWIFTLINT_STRICT` | Promotes every warning to an error. |
| `SWIFTLINT_COLOR` | Colorizes output by severity. |

### The pre-commit hook

Install it once per clone:

```sh
Scripts/install-git-hooks.sh
```

This points `core.hooksPath` at `Scripts/git-hooks`. The hook autocorrects, then validates strictly. If autocorrect changed a file, it refuses the commit, so the rewrite arrives as a diff to review and stage rather than landing unseen.
