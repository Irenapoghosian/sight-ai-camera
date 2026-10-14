import Foundation

/// How many objects with one label were found, for the result card.
public struct ObjectCount: Equatable, Sendable, Identifiable {
    public let label: String
    public let count: Int
    public let bestConfidence: Float

    public init(label: String, count: Int, bestConfidence: Float) {
        self.label = label
        self.count = count
        self.bestConfidence = bestConfidence
    }

    public var id: String { label }
    public var displayName: String { ResultRules.displayName(for: label) }
}
