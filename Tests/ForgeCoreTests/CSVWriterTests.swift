// Created by Dino Catalinac on 19.08.2026.

import Testing
@testable import ForgeCore

private let writer = CSVWriter()

@Test func writesAHeaderAndOneRecordPerRow() {
    let document = writer.document(
        header: ["Name", "Reps"],
        rows: [["Bench", "8"], ["Squat", "5"]]
    )

    #expect(document == "Name,Reps\r\nBench,8\r\nSquat,5\r\n")
}

/// A header on its own is a valid document — an export with nothing to say still
/// has columns.
@Test func writesAHeaderOnlyDocument() {
    #expect(writer.document(header: ["Name"], rows: [[String]]()) == "Name\r\n")
}

/// Ending with a terminator keeps the final line well-formed for POSIX tools and
/// makes appending start a new record.
@Test func endsWithATerminator() {
    #expect(writer.document(header: ["A"], rows: [["b"]]).hasSuffix("\r\n"))
}

// MARK: - Quoting

/// The whole reason quoting exists: an unquoted delimiter would split one field
/// into two.
@Test func quotesAFieldContainingTheDelimiter() {
    #expect(writer.document(header: ["A"], rows: [["one,two"]]) == "A\r\n\"one,two\"\r\n")
}

/// RFC 4180 escapes a quote by doubling it, inside a quoted field.
@Test func doublesAndQuotesAFieldContainingAQuote() {
    #expect(writer.document(header: ["A"], rows: [["say \"hi\""]]) == "A\r\n\"say \"\"hi\"\"\"\r\n")
}

@Test func quotesAFieldContainingALineFeed() {
    #expect(writer.document(header: ["A"], rows: [["one\ntwo"]]) == "A\r\n\"one\ntwo\"\r\n")
}

@Test func quotesAFieldContainingACarriageReturnLineFeed() {
    #expect(writer.document(header: ["A"], rows: [["one\r\ntwo"]]) == "A\r\n\"one\r\ntwo\"\r\n")
}

@Test func leavesAnOrdinaryFieldUnquoted() {
    #expect(writer.document(header: ["A"], rows: [["plain"]]) == "A\r\nplain\r\n")
}

@Test func writesAnEmptyFieldAsNothing() {
    #expect(writer.document(header: ["A", "B"], rows: [["", "b"]]) == "A,B\r\n,b\r\n")
}

/// Spaces are part of the field and RFC 4180 does not ask for them to be quoted,
/// so they must survive without being trimmed or wrapped.
@Test func keepsSurroundingSpacesWithoutQuoting() {
    #expect(writer.document(header: ["A"], rows: [["  x  "]]) == "A\r\n  x  \r\n")
}

@Test func quotesTheHeaderOnTheSameRules() {
    #expect(writer.document(header: ["a,b"], rows: [[String]]()) == "\"a,b\"\r\n")
}

// MARK: - Configuration

/// The quoting rule reads the configured delimiter: a semicolon document quotes
/// semicolons and leaves commas alone.
@Test func quotingFollowsTheConfiguredDelimiter() {
    let semicolonWriter = CSVWriter(delimiter: ";")

    let document = semicolonWriter.document(header: ["A"], rows: [["one;two"], ["one,two"]])

    #expect(document == "A\r\n\"one;two\"\r\none,two\r\n")
}

@Test func writesLineFeedTerminatorsWhenAsked() {
    let unixWriter = CSVWriter(lineEnding: .lf)

    #expect(unixWriter.document(header: ["A"], rows: [["b"]]) == "A\nb\n")
}

/// A carriage return still forces quoting under `.lf`, since it would otherwise
/// be read as a record break by a lenient parser.
@Test func quotesACarriageReturnEvenWithLineFeedTerminators() {
    let unixWriter = CSVWriter(lineEnding: .lf)

    #expect(unixWriter.document(header: ["A"], rows: [["one\rtwo"]]) == "A\n\"one\rtwo\"\n")
}

/// `some Sequence` so a caller can map lazily rather than materialising every row.
@Test func acceptsALazilyMappedSequence() {
    let document = writer.document(
        header: ["N"],
        rows: (1...3).lazy.map { [String($0)] }
    )

    #expect(document == "N\r\n1\r\n2\r\n3\r\n")
}
