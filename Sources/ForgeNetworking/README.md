# ForgeNetworking

Target-driven HTTP transport. An app describes its endpoints as `Target` values, supplies credentials through a `TokenProvider` and diagnostics through a `ForgeLogger`, and chooses the type its API returns in error bodies. Endpoint definitions, DTOs, and credential storage stay in the app.

## Setting up a service

```swift
import Foundation
import ForgeCore
import ForgeNetworking

struct APIErrorBody: Decodable, Sendable {
    let message: String
}

struct StoredTokenProvider: TokenProvider {
    let token: String

    func getToken() async throws -> String { token }
}

let service = NetworkService<APIErrorBody>(
    config: .init(
        baseURL: URL(string: "https://api.example.com").forceUnwrap,
        defaultHeaders: ["X-App-Version": "1.0"],
        verboseLogging: true,
        warningResponseTimeMs: 1_000,
        timeoutIntervalForRequest: 30,
        timeoutIntervalForResource: 60
    ),
    tokenProvider: StoredTokenProvider(token: accessToken),
    logger: appLogger  // Any ForgeLogger.
)
```

- The encoder writes ISO 8601 dates. The decoder converts snake-case keys and reads dates with ForgeCore's `.iso8601withOptionalFractionalSeconds`.
- Both timeouts default to 120 seconds; set them explicitly for your API.
- `getToken()` runs while each request is prepared, and a token it returns is sent as `Authorization: Bearer …`. If it throws for a target whose `isAuthenticationRequired` is `true`, the request fails with `APIError(.unauthorized)`; for other targets the request goes out without the header.
- The optional logger receives start, duration, slow-response (over `warningResponseTimeMs`), cancellation, decoding, and unexpected-error messages. In debug builds `verboseLogging` adds the multi-line cURL rendering of each request; release builds always log the compact one.

## Describing endpoints

`Target` needs a `path` and a `method`. Query items, body, extra headers, and the authentication requirement default to empty or `false`.

```swift
struct CreateTodoBody: Encodable {
    let title: String
}

enum TodosTarget: Target {
    case list
    case create(CreateTodoBody)

    var path: String { "/todos" }

    var method: HttpMethod {
        switch self {
        case .list: .get
        case .create: .post
        }
    }

    var bodyData: (any Encodable)? {
        switch self {
        case .list: nil
        case .create(let body): body
        }
    }

    var isAuthenticationRequired: Bool { true }
}
```

Keep endpoint enums and their DTOs in the feature or API module that owns them. Put headers every request needs in `Config.defaultHeaders`, and endpoint-specific ones in `additionalHeaders`. `requestDescription` renders the method and path for logs.

## Making requests

```swift
let todos: [Todo] = try await service.request(TodosTarget.list, responseType: [Todo].self)
try await service.request(TodosTarget.create(.init(title: "Buy milk")))  // No response body.
let raw = try await service.requestData(TodosTarget.list)
```

- Prefer the typed `request(_:responseType:)` for JSON. Use `requestData(_:)` only when the raw bytes are needed.
- `requestByteSequence(_:)` validates the response status, then yields each received byte as a one-byte `Data`. Framing and buffering are the caller's job.
- `upload(_:files:)` sends `UploadFile` parts (data, field name, filename, and a MIME type defaulting to `application/octet-stream`) as multipart form data, and decodes the response like `request`. Build a `MultipartRequest` directly when an API also needs string parts.
- `APIClient<TargetType, APIErrorResponse>(network:)` narrows a service to one target family, forwarding every call with the same configuration and error type.

## Errors

Every call is `async throws`:

- A status outside the success and redirection ranges throws `APIError<APIErrorResponse>`, carrying `statusCode` and, when the body decodes, `response`. `DefaultApiError` is `APIError<EmptyCodable>` for APIs without an error body.
- `NetworkError` covers the rest: `.url`, `.encoding`, `.decoding`, `.invalidResponse`, and `.unknown`.
- A cancelled request throws `CancellationError`.

```swift
do {
    let todos: [Todo] = try await service.request(TodosTarget.list, responseType: [Todo].self)
} catch let error as APIError<APIErrorBody> {
    // error.statusCode, error.response?.message
} catch let error as NetworkError {
    // Transport, serialization, or protocol failure.
} catch is CancellationError {
    // The calling task was cancelled.
}
```

## Request diagnostics

`URLRequest.cURL` and `cURLCompact` render a request for logs. They redact the values of `Authorization`, `Cookie`, `X-API-Key`, and `X-Auth-Token` (keeping a scheme such as `Bearer`) and replace the body with its byte count, so the output is not a runnable command.
