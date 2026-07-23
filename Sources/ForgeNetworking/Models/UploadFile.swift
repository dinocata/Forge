import Foundation

public struct UploadFile: Sendable {
    public let data: Data
    public let name: String
    public let filename: String
    public let mimeType: String

    public init(data: Data, name: String, filename: String, mimeType: String = "application/octet-stream") {
        self.data = data
        self.name = name
        self.filename = filename
        self.mimeType = mimeType
    }
}
