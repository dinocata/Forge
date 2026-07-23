import Foundation

public struct MultipartRequest {
    private var data = Data()
    private let boundary = UUID().uuidString
    private let separator = "\r\n"

    public init() {}

    public var headerValue: String { "multipart/form-data; boundary=\(boundary)" }
    public var httpBody: Data { data + Data("--\(boundary)--".utf8) }
    public var length: UInt64 { UInt64(httpBody.count) }

    public mutating func append(fileString: String, withName name: String) {
        appendHeader(name: name, filename: nil, mimeType: nil)
        data.append(Data(fileString.utf8))
        data.append(Data(separator.utf8))
    }

    public mutating func append(fileData: Data, withName name: String, fileName: String?, mimeType: String) {
        appendHeader(name: name, filename: fileName, mimeType: mimeType)
        data.append(fileData)
        data.append(Data(separator.utf8))
    }

    private mutating func appendHeader(name: String, filename: String?, mimeType: String?) {
        let safeName = sanitize(name)
        data.append(Data("--\(boundary)\(separator)Content-Disposition: form-data; name=\"\(safeName)\"".utf8))
        if let filename { data.append(Data("; filename=\"\(sanitize(filename))\"".utf8)) }
        data.append(Data(separator.utf8))
        if let mimeType { data.append(Data("Content-Type: \(mimeType)\(separator)".utf8)) }
        data.append(Data(separator.utf8))
    }

    private func sanitize(_ value: String) -> String {
        value.replacingOccurrences(of: "\r", with: "").replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: "\"", with: "\\\"")
    }
}
