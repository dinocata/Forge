# Forge

Forge is a Swift package of small, reusable foundations for Apple-platform applications. It provides common utilities in `ForgeCore` and a target-driven, async/await HTTP client in `ForgeNetworking`.

Use Forge to keep application-specific endpoint definitions, authentication storage, and logging implementations in an app while sharing the transport, request construction, multipart upload, decoding, and concurrency utilities across features.

## Features

- Two focused library products: `ForgeCore` and `ForgeNetworking`.
- Async utilities: retry with exponential backoff, async-sequence collection, and stream erasure.
- JSON decoding for ISO 8601 dates with optional fractional seconds and date-only fallback.
- Type-erased encoding with `AnyEncodable`.
- Optional, `Equatable`, and logging helpers.
- Target-driven HTTP requests with JSON encoding and decoding.
- Configurable base URL, default headers, timeouts, slow-request logging, and an injected authentication provider.
- Typed API error bodies, HTTP status-code classification, multipart uploads, and byte streaming.
- Sanitized cURL output that redacts selected sensitive headers and request bodies.

## Requirements

- Swift tools version: 6.3.3.
- iOS 18 or later.
- macOS 15 or later.
- Xcode 26.6 (the version used by this checkout).

Forge directly depends on [swift-async-algorithms](https://github.com/apple/swift-async-algorithms) from version 1.0.0.

## Installation

In Xcode, choose **File > Add Package Dependencies**, enter the repository URL below, select an available release rule, then add the products your target needs:

```text
https://github.com/dinocata/Forge.git
```

When adding Forge from another package manifest, use the same URL and replace `<released-version>` with a version that has been published by the repository:

```swift
dependencies: [
    .package(
        url: "https://github.com/dinocata/Forge.git",
        from: "<released-version>"
    )
]
```

Add the required products to your target:

```swift
.target(
    name: "MyApp",
    dependencies: [
        .product(name: "ForgeCore", package: "Forge"),
        .product(name: "ForgeNetworking", package: "Forge")
    ]
)
```

### Library products

| Product | Responsibility |
| --- | --- |
| `ForgeCore` | General-purpose utilities, logging abstractions, JSON date decoding, and async-sequence helpers. |
| `ForgeNetworking` | HTTP transport, request targets, authentication integration, errors, uploads, and HTTP-specific models. Depends on `ForgeCore`. |

## Package Structure

```text
Forge
├── ForgeCore
│   ├── Concurrency extensions and async retry
│   ├── JSON decoding and encoding utilities
│   ├── Optional and Equatable helpers
│   └── ForgeLogger and LogLevel
└── ForgeNetworking
    ├── Target and AuthProvider protocols
    ├── NetworkService and APIClient
    ├── HTTP methods, status codes, and errors
    ├── Multipart upload types
    └── URLRequest construction and cURL rendering
```

`ForgeCore` does not depend on `ForgeNetworking`. Put generic, non-HTTP utilities there. Put HTTP transport concerns in `ForgeNetworking`; define concrete endpoints, API-error bodies, credentials, and logger implementations in the consuming application.

## Quick Start

Define an authentication provider and an endpoint type, then create a `NetworkService` with the API's error-response model.

```swift
import Foundation
import ForgeNetworking

struct APIErrorBody: Decodable, Sendable {
    let message: String
}

struct TokenProvider: AuthProvider {
    func getToken() async throws -> String {
        "your-access-token"
    }
}

enum TodoTarget: Target {
    case todos

    var path: String { "/todos" }
    var method: HttpMethod { .get }
}

struct Todo: Decodable {
    let id: Int
    let title: String
}

let service = NetworkService<APIErrorBody>(
    config: .init(baseURL: URL(string: "https://api.example.com")!),
    authProvider: TokenProvider()
)

let todos: [Todo] = try await service.request(
    TodoTarget.todos,
    responseType: [Todo].self
)
```

## Usage

### ForgeCore

#### `asyncRetry`

`asyncRetry` runs an asynchronous throwing operation again after failures. Its default policy makes four total attempts, waiting one second before the first retry and doubling the delay up to 100 seconds. Set `maxAttempts` to `0` for unlimited attempts. The operation and optional retry handler are `@Sendable`.

```swift
import ForgeCore

let data = try await asyncRetry(
    maxAttempts: 3,
    initialInterval: 0.5,
    retryHandler: { error in
        // Inspect the error or update application diagnostics before retrying.
        print("Retrying after: \(error.localizedDescription)")
    }
) {
    try await URLSession.shared.data(from: URL(string: "https://example.com")!).0
}
```

Cancellation is checked after the retry handler and before each delay; cancellation stops the retry loop by throwing.

#### `AsyncSequence` utilities

`collect()` consumes a finite async sequence into an array. It is available when both the sequence and its elements are `Sendable`.

```swift
import ForgeCore

let values = await AsyncStream<Int> { continuation in
    continuation.yield(1)
    continuation.yield(2)
    continuation.finish()
}.collect()
// [1, 2]
```

`eraseToStream()` and `eraseToThrowingStream()` turn a sendable async sequence into `AsyncStream` and `AsyncThrowingStream`, respectively. The generated task is cancelled when the stream terminates.

```swift
let stream = someSendableAsyncSequence.eraseToThrowingStream()

for try await value in stream {
    // Consume values until the underlying sequence finishes or throws.
}
```

#### JSON and encoding helpers

`JSONDecoder.DateDecodingStrategy.iso8601withOptionalFractionalSeconds` decodes ISO 8601 dates with fractional seconds, ISO 8601 dates without them, and date-only values in year-month-day form.

```swift
import ForgeCore

let decoder = JSONDecoder()
decoder.dateDecodingStrategy = .iso8601withOptionalFractionalSeconds
```

Use `AnyEncodable` (or `wrapToAnyEncodable`) when an API accepts an `Encodable` value whose concrete type is not known statically.

```swift
let body: any Encodable = ["enabled": true]
let encoded = AnyEncodable(body)
```

`Equatable.isOneOf(_:)` checks a value against a variadic list. `isEqualTo(_:)` safely compares against an `any Equatable` value of a potentially different concrete type. `Optional` adds `isSome`, `isNone`, `forceUnwrap`, and `isEmptyOrNil` for optional strings and collections.

#### `ForgeLogger`

`ForgeLogger` is the logging integration point. Implement `log` and `capture`; default arguments on the extension add the call-site file, function, and line automatically.

```swift
import ForgeCore

struct ConsoleLogger: ForgeLogger {
    func log(message: String, level: LogLevel, file: StaticString, function: StaticString, line: UInt) {
        print("[\(level.rawValue)] \(message)")
    }

    func capture(error: Error, message: String?, file: StaticString, function: StaticString, line: UInt) {
        print("\(message ?? "Error"): \(error.localizedDescription)")
    }
}
```

`LogLevel.shouldInclude(_:)` can be used by logger implementations to apply a level threshold.

### ForgeNetworking

#### `Target`

`Target` describes an endpoint independently of the transport. Every target supplies a path and HTTP method; query items, body data, headers, authentication requirement, and ignored status-code set have default empty or `false` implementations.

```swift
import Foundation
import ForgeNetworking

struct CreateTodoBody: Encodable {
    let title: String
}

enum TodosTarget: Target {
    case create(CreateTodoBody)

    var path: String { "/todos" }
    var method: HttpMethod { .post }
    var bodyData: (any Encodable)? {
        switch self {
        case .create(let body): body
        }
    }
    var additionalHeaders: [String: String] {
        ["X-Client": "MyApp"]
    }
    var isAuthenticationRequired: Bool { true }
}
```

`requestDescription` provides a method-and-path string suitable for logging. `URLRequest(baseURL:target:bodyEncoder:)` constructs the request, encodes `bodyData` with the supplied `JSONEncoder`, and percent-encodes `+` in query values.

#### Authentication and logging

`NetworkService` always receives an `AuthProvider`. `getToken()` is called while preparing a request. If it succeeds, the service writes the token as a `Bearer` value in the `Authorization` header. If it fails for a target whose `isAuthenticationRequired` is `true`, the service throws its typed `APIError` with `.unauthorized`.

Pass an optional `ForgeLogger` to receive start, duration, cancellation, decoding, and unexpected-error messages. With `verboseLogging` enabled in debug builds, request logs use the multi-line cURL representation; in non-debug builds they use the compact representation.

```swift
let service = NetworkService<APIErrorBody>(
    config: .init(
        baseURL: URL(string: "https://api.example.com")!,
        defaultHeaders: ["X-App-Version": "1.0"],
        verboseLogging: true,
        warningResponseTimeMs: 1_000,
        timeoutIntervalForRequest: 30,
        timeoutIntervalForResource: 60
    ),
    authProvider: TokenProvider(),
    logger: ConsoleLogger()
)
```

#### `NetworkService`

`NetworkService<APIErrorResponse>` is the transport entry point. The generic `APIErrorResponse` is decoded from a non-success HTTP response when possible. The service configures a JSON encoder with ISO 8601 date encoding and a JSON decoder with snake-case key decoding plus ForgeCore's date strategy.

```swift
struct Todo: Decodable {
    let id: Int
    let title: String
}

let todo: Todo = try await service.request(
    TodosTarget.create(.init(title: "Buy milk")),
    responseType: Todo.self
)

let rawData = try await service.requestData(TodosTarget.create(.init(title: "Buy milk")))
```

For an endpoint with no response body, call `request(_:)`. An empty successful response is decoded as `EmptyCodable` for that overload.

Use `requestByteSequence(_:)` for a streaming response. It validates the initial HTTP response, then maps each received byte to `Data`.

```swift
let bytes = try await service.requestByteSequence(TodoTarget.todos)

for try await byte in bytes {
    // `byte` is a one-byte Data value.
}
```

#### `APIClient`

`APIClient<TargetType, APIErrorResponse>` narrows a `NetworkService` to one target family. It forwards request, data, streaming, and upload calls while preserving the same configuration and error type.

```swift
let todos = APIClient<TodosTarget, APIErrorBody>(network: service)
let todo: Todo = try await todos.request(
    .create(.init(title: "Buy milk")),
    responseType: Todo.self
)
```

#### Multipart uploads

`UploadFile` describes a file part with bytes, multipart field name, filename, and MIME type. Its MIME type defaults to `application/octet-stream`. `NetworkService.upload` assembles the file parts into a `MultipartRequest` and decodes the response using the same rules as a regular request.

```swift
let image = UploadFile(
    data: imageData,
    name: "image",
    filename: "avatar.jpg",
    mimeType: "image/jpeg"
)

enum AvatarTarget: Target {
    case upload

    var path: String { "/avatar" }
    var method: HttpMethod { .post }
    var isAuthenticationRequired: Bool { true }
}

let uploaded: Todo = try await service.upload(
    AvatarTarget.upload,
    files: [image]
)
```

`MultipartRequest` is public for callers that need to assemble multipart bodies directly. It provides `append(fileString:withName:)`, `append(fileData:withName:fileName:mimeType:)`, the `Content-Type` header value, body data, and body length. `NetworkService.upload` assembles the `UploadFile` values supplied to it; use `MultipartRequest` directly if an API requires additional string parts.

#### HTTP values and request diagnostics

`HttpMethod` contains `HEAD`, `GET`, `POST`, `PUT`, `PATCH`, and `DELETE`. `HttpStatusCode` provides the status codes recognized by the service, category checks (`isSuccess`, `isRedirection`, `isClientError`, and `isServerError`), and a localized description.

`URLRequest.cURL` and `cURLCompact` produce log-oriented cURL commands. They redact `Authorization`, `Cookie`, `X-API-Key`, and `X-Auth-Token` headers, and replace the request body with its byte count. Do not treat the output as an executable request representation.

```swift
var request = URLRequest(url: URL(string: "https://api.example.com/todos")!)
request.httpMethod = HttpMethod.post.rawValue
request.setValue("Bearer secret", forHTTPHeaderField: "Authorization")
request.httpBody = Data("{\"title\":\"Buy milk\"}".utf8)

print(request.cURLCompact)
// The token and body contents are redacted.
```

## Architecture

Forge has a one-way dependency graph:

```text
ForgeNetworking ──> ForgeCore ──> swift-async-algorithms
```

`ForgeCore` exports its utilities directly. `ForgeNetworking` imports `ForgeCore` for `ForgeLogger` and the date-decoding strategy, then builds requests through `Target`, obtains credentials through `AuthProvider`, and executes them with an internally configured `URLSession`.

The public extension points are deliberately protocol-based:

- Implement `Target` for each endpoint family.
- Implement `AuthProvider` for application-owned credential retrieval.
- Implement `ForgeLogger` for application-owned logging.
- Choose the `APIErrorResponse` generic argument that matches an API's error JSON.

Implementation details such as header application, response validation, decoding diagnostics, error translation, multipart boundaries, and JSON pretty printing are private to their modules.

## Error Handling

All network operations are `async throws`.

- `APIError<APIErrorResponse>` is thrown for recognized non-success/non-redirection HTTP status codes. When the response body decodes as `APIErrorResponse`, it is exposed through `response`; otherwise it is `nil`.
- `DefaultApiError` is `APIError<EmptyCodable>` for APIs that do not expose a separate decodable error-body type.
- `NetworkError.url`, `.encoding`, `.decoding`, `.invalidResponse`, and `.unknown` represent transport, serialization, protocol, and unexpected failures.
- A cancelled URL request is surfaced as `CancellationError`.
- Authentication-token failure for an authentication-required target is surfaced as `APIError<APIErrorResponse>(.unauthorized)`.

Handle the typed API error first, then fall back to `NetworkError` or other errors:

```swift
do {
    let todo: Todo = try await service.request(TodoTarget.todos, responseType: Todo.self)
    _ = todo
} catch let error as APIError<APIErrorBody> {
    print("HTTP \(error.statusCode.rawValue): \(error.response?.message ?? "No API error body")")
} catch let error as NetworkError {
    print(error.localizedDescription)
} catch is CancellationError {
    // The calling task was cancelled.
}
```

## Thread Safety and Concurrency

Forge uses Swift concurrency throughout:

- `NetworkService`, `APIClient`, `Target`, `AuthProvider`, `ForgeLogger`, `UploadFile`, HTTP value types, and API error types carry `Sendable` constraints or conformances where declared by the source.
- Network requests, uploads, token retrieval, retry handling, and async-sequence consumption use `async`/`await`.
- `AsyncSequence.collect()` requires a sendable sequence and sendable elements because it delegates to concurrent reduction.
- Stream-erasure helpers create a task to consume the source sequence and cancel it when the consumer terminates the stream.
- Forge does not impose a global actor. Callers remain responsible for updating UI state on the appropriate actor and for making their own `AuthProvider` and `ForgeLogger` implementations safe for their internal state.

## Best Practices

- Keep endpoint enums and request/response DTOs in the feature or API module that owns them; use `Target` only as the transport boundary.
- Define one `APIErrorResponse` type per API contract and use it consistently in the corresponding `NetworkService` and `APIClient`.
- Set explicit request and resource timeouts for your service rather than relying on the 120-second defaults.
- Supply default headers through `NetworkService.Config` and endpoint-specific headers through `Target.additionalHeaders`.
- Use `requestData(_:)` only when raw bytes are required; prefer typed `request(_:responseType:)` for JSON responses.
- Use `requestByteSequence(_:)` for byte-oriented streaming. It yields one-byte `Data` values, so framing and buffering belong to the caller.
- Treat cURL diagnostics as logs only. Although supported headers and bodies are redacted, do not rely on the output as a copy-and-run command.
- Use `asyncRetry` only for operations that are safe to repeat, and customize `retryHandler` to avoid retrying non-transient errors.

## Development

Build the package from the repository root:

```sh
swift build
```

Run its test targets:

```sh
swift test
```

When contributing, keep shared language and concurrency utilities in `ForgeCore`; keep HTTP-specific behavior in `ForgeNetworking`. Add focused tests alongside the affected target under `Tests`.

## License

No license file is currently included. Add the project's license terms here.
