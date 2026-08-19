// Created by Dino Catalinac on 19.08.2026.

/// Writes delimiter-separated values, quoting fields the way RFC 4180 requires.
///
/// Returns a `String` rather than `Data` or a file: encoding and where it lands
/// are the caller's decisions, and a string is what a test can read.
///
/// ```swift
/// CSVWriter().document(
///     header: ["Name", "Note"],
///     rows: entries.lazy.map { [$0.name, $0.note] }
/// )
/// ```
///
/// Deliberately write-only. A correct reader is a much larger problem — quoted
/// fields containing the delimiter, embedded line breaks, ragged records, byte
/// order marks, streaming — and it should be written when something actually
/// needs to parse CSV, so its callers can shape it.
public struct CSVWriter: Sendable {

    /// How records are terminated.
    ///
    /// An enum rather than a string so `lineEnding: "banana"` cannot be written.
    /// RFC 4180 specifies CRLF; `lf` is here because Unix tooling generally
    /// prefers it and the choice costs nothing.
    public enum LineEnding: String, Sendable {
        case crlf = "\r\n"
        case lf = "\n"
    }

    private let delimiter: Character
    private let lineEnding: LineEnding

    public init(delimiter: Character = ",", lineEnding: LineEnding = .crlf) {
        self.delimiter = delimiter
        self.lineEnding = lineEnding
    }

    /// A complete document: the header record, then one record per row.
    ///
    /// The document ends with a terminator, so appending to it starts a new
    /// record and POSIX tools see a well-formed final line.
    ///
    /// Rows are expected to match the header's width — RFC 4180 says every record
    /// carries the same number of fields — but a mismatch is written rather than
    /// refused, since discarding a caller's data is worse than emitting a ragged
    /// file. It trips an assertion in debug so the row builder is fixed instead.
    public func document(header: [String], rows: some Sequence<[String]>) -> String {
        var document = record(header)

        for row in rows {
            assert(
                row.count == header.count,
                "CSV row has \(row.count) fields, header has \(header.count)"
            )

            document += record(row)
        }

        return document
    }

    /// One terminated record.
    private func record(_ fields: [String]) -> String {
        fields.map(escaped).joined(separator: String(delimiter)) + lineEnding.rawValue
    }

    /// Quotes a field only where it would otherwise be misread, and doubles any
    /// quote inside it.
    ///
    /// Keyed off the configured delimiter rather than a hardcoded comma, so a
    /// semicolon-separated document quotes semicolons and leaves commas alone.
    ///
    /// **Line breaks are found by unicode scalar, not by `Character`.** Swift
    /// treats CRLF as a single grapheme cluster, so a `Character` comparison
    /// against "\r" and "\n" matches neither and a field carrying a Windows line
    /// break would go out unquoted — which is a corrupt document, not a cosmetic
    /// one. The delimiter stays a `Character` comparison because a delimiter may
    /// legitimately be more than one scalar.
    private func escaped(_ field: String) -> String {
        let containsLineBreakOrQuote = field.unicodeScalars.contains { scalar in
            scalar == "\"" || scalar == "\r" || scalar == "\n"
        }

        guard containsLineBreakOrQuote || field.contains(delimiter) else {
            return field
        }

        return "\"\(field.replacingOccurrences(of: "\"", with: "\"\""))\""
    }
}
