//
//  FuzzySearch.swift
//  Applite
//
//  Created by Milán Várady on 2025.
//

import Foundation

/// A weighted search property for fuzzy matching
struct FuzzySearchProperty: Sendable {
    let text: String
    let weight: Double

    init(_ text: String, weight: Double = 1.0) {
        self.text = text
        self.weight = weight
    }
}

/// Protocol for types that can be fuzzy searched
protocol FuzzySearchable {
    var searchProperties: [FuzzySearchProperty] { get }
}

/// Result of a fuzzy search operation
struct FuzzySearchResult {
    let index: Int
    let score: Double
}

/// Performs fuzzy search on a collection of items
enum FuzzySearch {
    /// Search for a query in a collection, returning results sorted by score (lower is better match)
    static func search<T>(
        _ query: String,
        in items: [T],
        by keyPath: KeyPath<T, [FuzzySearchProperty]>
    ) async -> [FuzzySearchResult] {
        let lowercasedQuery = query.lowercased()

        var results: [FuzzySearchResult] = []

        for (index, item) in items.enumerated() {
            let properties = item[keyPath: keyPath]
            var bestScore = Double.infinity

            for property in properties {
                let text = property.text.lowercased()
                let weight = property.weight
                let score = computeScore(query: lowercasedQuery, text: text)

                if score < Double.infinity {
                    let weightedScore = score / weight
                    bestScore = min(bestScore, weightedScore)
                }
            }

            if bestScore < Double.infinity {
                results.append(FuzzySearchResult(index: index, score: bestScore))
            }
        }

        results.sort { $0.score < $1.score }
        return results
    }

    /// Compute a fuzzy match score between query and text.
    /// Returns Double.infinity for no match. Lower scores = better match.
    /// Score range: 0 (perfect) to 1 (worst match). Threshold of ~0.2-0.3 filters weak matches.
    private static func computeScore(query: String, text: String) -> Double {
        if query.isEmpty { return 0 }
        if text.isEmpty { return .infinity }

        // Exact match
        if text == query { return 0 }

        // Prefix match — very strong signal
        if text.hasPrefix(query) {
            return 0.01
        }

        // Contains as substring
        if text.contains(query) {
            // Score based on how much of the text the query covers
            let coverage = Double(query.count) / Double(text.count)
            return 0.02 + (1.0 - coverage) * 0.08 // Range: 0.02 - 0.10
        }

        // Fuzzy character-by-character matching
        let queryChars = Array(query)
        let textChars = Array(text)

        var queryIndex = 0
        var lastMatchIndex = -1
        var totalGap = 0
        var matchedPositions: [Int] = []
        var consecutiveMatches = 0
        var maxConsecutive = 0

        for (textIndex, textChar) in textChars.enumerated() {
            guard queryIndex < queryChars.count else { break }

            if textChar == queryChars[queryIndex] {
                matchedPositions.append(textIndex)
                if lastMatchIndex >= 0 {
                    let gap = textIndex - lastMatchIndex - 1
                    totalGap += gap
                    if gap == 0 {
                        consecutiveMatches += 1
                        maxConsecutive = max(maxConsecutive, consecutiveMatches)
                    } else {
                        consecutiveMatches = 0
                    }
                }
                lastMatchIndex = textIndex
                queryIndex += 1
            }
        }

        // Not all query characters found
        guard queryIndex == queryChars.count else {
            return .infinity
        }

        // Score components (each 0-1, lower is better)
        let queryLen = Double(queryChars.count)
        let textLen = Double(textChars.count)

        // How spread out are the matches? 0 = perfectly consecutive
        let maxPossibleGap = textLen - queryLen
        let gapScore = maxPossibleGap > 0 ? Double(totalGap) / maxPossibleGap : 0

        // How early do matches start? 0 = starts at beginning
        let startScore = Double(matchedPositions.first ?? 0) / textLen

        // What fraction of query chars were consecutive? 1 = all consecutive
        let consecutiveRatio = queryLen > 1 ? Double(maxConsecutive) / (queryLen - 1) : 1.0

        // How much of the text does the query cover?
        let coverageScore = 1.0 - (queryLen / textLen)

        // Weighted combination — tuned so decent fuzzy matches score ~0.1-0.2
        let score = gapScore * 0.35 + startScore * 0.15 + (1.0 - consecutiveRatio) * 0.3 + coverageScore * 0.2
        return min(max(score, 0.01), 1.0)
    }
}
