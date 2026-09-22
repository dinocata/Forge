# Forge

Forge is a Swift package of reusable, app-agnostic foundations for Apple-platform applications: general utilities in `ForgeCore`, HTTP transport in `ForgeNetworking`, SwiftData and `UserDefaults` infrastructure in `ForgePersistence`, and SwiftUI building blocks in `ForgeUI`. Apps keep their own models, endpoints, credentials, and design systems; Forge supplies what those sit on.

## Requirements

- Swift tools 6.3.3, Swift 6 language mode
- iOS 18 or later, macOS 15 or later
- Xcode 26.6

Forge depends on [swift-algorithms](https://github.com/apple/swift-algorithms) and [swift-async-algorithms](https://github.com/apple/swift-async-algorithms).

## Installation

Forge has no tagged releases; depend on its `main` branch. In Xcode, choose **File > Add Package Dependencies**, enter the URL below, and pick the `main` branch. From a package manifest:

```swift
dependencies: [
    .package(url: "https://github.com/dinocata/Forge.git", branch: "main")
]
```

Then add the products a target needs, such as `.product(name: "ForgeCore", package: "Forge")`. Each consumer pins the revision it last resolved, so a change to `main` reaches it only when it resolves package versions again.

## Products

| Product | Responsibility | Depends on |
| --- | --- | --- |
| `ForgeCore` | General-purpose utilities, concurrency, coding, logging, validation, and state types. | — |
| `ForgeNetworking` | HTTP transport, request targets, authentication, uploads, and network errors. | `ForgeCore` |
| `ForgePersistence` | SwiftData container and record-reconciliation abstractions, and Codable `UserDefaults` storage. | `ForgeCore` |
| `ForgeUI` | SwiftUI navigation, layout, components, view modifiers, transitions, and Codable app storage. | `ForgeCore`, `ForgePersistence` |

### ForgeCore

- **Concurrency** — `asyncRetry` with exponential backoff; `TaskQueue`; `AsyncSequence` `collect()`, `eraseToStream()`, and `eraseToThrowingStream()`; `Sequence` `asyncMap`, `concurrentMap`, and `concurrentForEach`.
- **Collections** — `IdentifiedArray`, an ordered collection of identifiable elements; `Sequence` conversions to sets, ordered sets, and identified arrays or dictionaries, and duplicate removal; `Collection.elementsBracketing` for sorted collections; `ArrayBuilder`.
- **Coding** — the `.iso8601withOptionalFractionalSeconds` date-decoding strategy; conversion between Codable values and JSON-compatible dictionaries; `AnyEncodable`; `CodableDefault` for keys that may be missing; `OptionalValue`; `CSVWriter`.
- **State** — `ResultState` and the observable `AsyncState` for loading, success, and failure; `PaginationStore` and `PaginationResponse` for cursor-based pagination.
- **Validation** — the `Validator` and `AsyncValidator` protocols, built-in validators (required, length, display name, URL, and more), and `FormFieldState` with a text-field validation modifier.
- **Dates** — `DateProvider` for an injectable current date; `Date` helpers for day boundaries, relative day names, and age; `Calendar` component comparisons.
- **Logging** — the `ForgeLogger` protocol and `LogLevel`.
- **Small helpers** — `Optional` (`isSome`, `isNone`, `forceUnwrap`, `isEmptyOrNil`), `Equatable` (`isOneOf`, `isEqualTo`), `String.trimmed`, and `Bundle` app name and version.

### ForgeNetworking

`NetworkService` and `APIClient` execute `Target`-described requests, with a `TokenProvider` for credentials, typed API error bodies, multipart uploads, byte streaming, and redacted cURL logging. See [`Sources/ForgeNetworking/README.md`](Sources/ForgeNetworking/README.md) for usage.

### ForgePersistence

- `ModelContainerManager` for building and clearing a SwiftData container.
- `DomainRepresentable`, `IdentifiedRecord`, and `MergeableRecord` for converting between records and domain values, upserting top-level records, and reconciling child records in place.
- Codable storage in `UserDefaults`.

### ForgeUI

- **Navigation** — `Router`, `RouterView`, and `DestinationType` for stack navigation driven by destination values.
- **Components** — `FlowLayout`, `InfiniteCarousel`, and `ShareSheet`.
- **View modifiers** — `adaptiveSheet`, `asButton`, `pulsing`, `stretchy`, and `revealsFocusedField`.
- **Storage** — `CodableAppStorage` for Codable values in app storage.
- **Small helpers** — move-offset transitions, CSS-angle `LinearGradient`, uniform `EdgeInsets`, and per-element `Binding`s.

Usage for each API is in its doc comments.

## Development

```sh
swift build
swift test
SWIFTLINT_STRICT=1 Scripts/swiftlint.sh
```

Nothing lints during `swift build`; the pre-commit hook does. Install it once with `Scripts/install-git-hooks.sh`. [`Scripts/README.md`](Scripts/README.md) explains the lint setup, and [`AGENTS.md`](AGENTS.md) has the contributor rules.

## License

No license file is currently included.
