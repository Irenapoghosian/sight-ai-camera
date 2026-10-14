import CoreGraphics
import Foundation

/// Pure rules that turn raw model output into what the screen shows.
public enum ResultRules {

    /// The strongest labels first, without the noise at the bottom of the list.
    public static func topClassifications(
        _ labels: [Classification],
        minimumConfidence: Float = 0.1,
        limit: Int = 3
    ) -> [Classification] {
        Array(
            labels
                .filter { $0.confidence >= minimumConfidence }
                .sorted { $0.confidence > $1.confidence }
                .prefix(limit)
        )
    }

    /// "golden_retriever" → "Golden retriever", "sky" → "Sky".
    public static func displayName(for identifier: String) -> String {
        let words = identifier
            .replacingOccurrences(of: "_", with: " ")
            .trimmingCharacters(in: .whitespaces)
        guard let first = words.first else { return identifier }
        return first.uppercased() + words.dropFirst()
    }

    /// Drops blank lines and lines the recognizer wasn't sure about.
    public static func filteredText(_ lines: [RecognizedText], minimumConfidence: Float = 0.3) -> [RecognizedText] {
        lines.filter { line in
            line.confidence >= minimumConfidence
                && !line.string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    /// Groups text into rows (top to bottom), each row read left to right.
    ///
    /// Vision's origin is bottom-left, so a higher `midY` means higher on the page.
    /// Two boxes share a row when their centers are less than half a line apart.
    public static func rows(_ lines: [RecognizedText]) -> [[RecognizedText]] {
        let topDown = lines.sorted { $0.boundingBox.midY > $1.boundingBox.midY }
        var rows: [[RecognizedText]] = []
        for line in topDown {
            if let anchor = rows.last?.first, sharesRow(line, anchor) {
                rows[rows.count - 1].append(line)
            } else {
                rows.append([line])
            }
        }
        return rows.map { row in row.sorted { $0.boundingBox.minX < $1.boundingBox.minX } }
    }

    /// Everything flattened into reading order.
    public static func readingOrder(_ lines: [RecognizedText]) -> [RecognizedText] {
        rows(lines).flatMap { $0 }
    }

    /// Rows joined by newlines, boxes within a row by spaces.
    public static func joinedText(_ lines: [RecognizedText]) -> String {
        rows(lines)
            .map { row in row.map(\.string).joined(separator: " ") }
            .joined(separator: "\n")
    }

    private static func sharesRow(_ line: RecognizedText, _ anchor: RecognizedText) -> Bool {
        let lineHeight = min(line.boundingBox.height, anchor.boundingBox.height)
        return abs(line.boundingBox.midY - anchor.boundingBox.midY) < lineHeight / 2
    }
}
