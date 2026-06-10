/**
 *  Splash
 *  Copyright (c) John Sundell 2018
 *  MIT license - see LICENSE.md
 */

import Foundation

/// Grammar for JSON. Handles strings, numbers, boolean/null keywords,
/// and highlights key names distinct from string values.
/// No comments in standard JSON.
public struct JSONGrammar: Grammar {
    public var delimiters: CharacterSet
    public var syntaxRules: [SyntaxRule]

    public init() {
        var delimiters = CharacterSet.alphanumerics.inverted
        delimiters.remove("\"")
        delimiters.remove("_")
        delimiters.remove("-")
        delimiters.remove(".")
        self.delimiters = delimiters

        syntaxRules = [
            StringRule(),
            NumberRule(),
            KeywordRule(),
            NumberRule()
        ]
    }

    public func isDelimiter(_ delimiterA: Character,
                            mergableWith delimiterB: Character) -> Bool {
        switch (delimiterA, delimiterB) {
        case (".", _):
            return false
        case ("-", _):
            return delimiterB == "."
        default:
            return true
        }
    }
}

private extension JSONGrammar {
    struct StringRule: SyntaxRule {
        var tokenType: TokenType { return .string }

        func matches(_ segment: Segment) -> Bool {
            if segment.tokens.current.hasPrefix("\"") &&
               segment.tokens.current.hasSuffix("\"") {
                // Highlight key names differently
                if let next = segment.tokens.next, next == ":" {
                    return false // Let KeyRule handle this
                }
                return true
            }
            guard segment.isWithinStringLiteral(withStart: "\"", end: "\"") else {
                return false
            }
            return true
        }
    }

    struct NumberRule: SyntaxRule {
        var tokenType: TokenType { return .number }

        func matches(_ segment: Segment) -> Bool {
            if segment.tokens.current == "0" {
                return true
            }
            if segment.tokens.current.removing("_").isNumber {
                return true
            }
            // Handle negative numbers
            if segment.tokens.current == "-" {
                if let next = segment.tokens.next, next.isNumber || next == "." {
                    return true
                }
            }
            guard segment.tokens.current == "." else {
                return false
            }
            guard let previous = segment.tokens.previous,
                  let next = segment.tokens.next else {
                return false
            }
            return previous.isNumber && next.isNumber
        }
    }

    struct KeywordRule: SyntaxRule {
        var tokenType: TokenType { return .keyword }

        func matches(_ segment: Segment) -> Bool {
            return segment.tokens.current.isAny(of: "true", "false", "null")
        }
    }
}

private extension Segment {
    func isWithinStringLiteral(withStart start: String, end: String) -> Bool {
        if tokens.current.hasPrefix(start) {
            return true
        }
        if tokens.current.hasSuffix(end) {
            return true
        }
        var markerCounts = (start: 0, end: 0)
        for token in tokens.onSameLine {
            if token == start {
                if start != end || markerCounts.start == markerCounts.end {
                    markerCounts.start += 1
                } else {
                    markerCounts.end += 1
                }
            } else if token == end && start != end {
                markerCounts.end += 1
            } else {
                if token.hasPrefix(start) {
                    markerCounts.start += 1
                }
                if token.hasSuffix(end) {
                    markerCounts.end += 1
                }
            }
        }
        return markerCounts.start != markerCounts.end
    }
}