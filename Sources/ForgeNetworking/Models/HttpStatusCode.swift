import Foundation

public enum HttpStatusCode: Int, Sendable, CaseIterable {
    /// 200
    case ok = 200
    /// 201
    case created = 201
    /// 202
    case accepted = 202
    /// 203
    case nonAuthoritativeInformation = 203
    /// 204
    case noContent = 204
    /// 205
    case resetContent = 205
    /// 206
    case partialContent = 206
    /// 207
    case multiStatus = 207
    /// 208
    case alreadyReported = 208
    /// 226
    case imUsed = 226

    /// 300
    case multipleChoices = 300
    /// 301
    case movedPermanently = 301
    /// 302
    case found = 302
    /// 303
    case seeOther = 303
    /// 304
    case notModified = 304
    /// 305
    case useProxy = 305
    /// 306
    case unused = 306
    /// 307
    case temporaryRedirect = 307
    /// 308
    case permanentRedirect = 308

    /// 400
    case badRequest = 400
    /// 401
    case unauthorized = 401
    /// 402
    case paymentRequired = 402
    /// 403
    case forbidden = 403
    /// 404
    case notFound = 404
    /// 405
    case methodNotAllowed = 405
    /// 406
    case notAcceptable = 406
    /// 407
    case proxyAuthenticationRequired = 407
    /// 408
    case requestTimeout = 408
    /// 409
    case conflict = 409
    /// 410
    case gone = 410
    /// 411
    case lengthRequired = 411
    /// 412
    case preconditionFailed = 412
    /// 413
    case payloadTooLarge = 413
    /// 414
    case uriTooLong = 414
    /// 415
    case unsupportedMediaType = 415
    /// 416
    case rangeNotSatisfiable = 416
    /// 417
    case expectationFailed = 417
    /// 418
    case teapot = 418
    /// 421
    case misdirectedRequest = 421
    /// 422
    case unprocessableContent = 422
    /// 423
    case locked = 423
    /// 424
    case failedDependency = 424
    /// 425
    case tooEarly = 425
    /// 426
    case upgradeRequired = 426
    /// 428
    case preconditionRequired = 428
    /// 429
    case tooManyRequests = 429
    /// 431
    case requestHeaderFieldsTooLarge = 431
    /// 451
    case unavailableForLegalReasons = 451

    /// 500
    case internalServerError = 500
    /// 501
    case notImplemented = 501
    /// 502
    case badGateway = 502
    /// 503
    case serviceUnavailable = 503
    /// 504
    case gatewayTimeout = 504
    /// 505
    case httpVersionNotSupported = 505
    /// 506
    case variantAlsoNegotiates = 506
    /// 507
    case insufficientStorage = 507
    /// 508
    case loopDetected = 508
    /// 510
    case notExtended = 510
    /// 511
    case networkAuthenticationRequired = 511

    public var isSuccess: Bool { 200..<300 ~= rawValue }
    public var isRedirection: Bool { 300..<400 ~= rawValue }
    public var isClientError: Bool { 400..<500 ~= rawValue }
    public var isServerError: Bool { 500..<600 ~= rawValue }
}

extension HttpStatusCode: CustomStringConvertible {
    public var description: String { "[\(rawValue)] \(textDescription)" }

    private var textDescription: String {
        HTTPURLResponse.localizedString(forStatusCode: rawValue).capitalized
    }
}
