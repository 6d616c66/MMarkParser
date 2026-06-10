/**
 *  Splash
 *  Copyright (c) John Sundell 2018
 *  MIT license - see LICENSE.md
 */

import Foundation

/// Grammar for the Python language. Handles Python 3 syntax:
/// keywords, strings (single/double/triple-quoted), comments (#),
/// numbers, function calls, and type names.
public struct PythonGrammar: Grammar {
    public var delimiters: CharacterSet
    public var syntaxRules: [SyntaxRule]

    public init() {
        var delimiters = CharacterSet.alphanumerics.inverted
        delimiters.remove("_")
        delimiters.remove("\"")
        delimiters.remove("'")
        delimiters.remove("#")
        delimiters.remove(".")
        self.delimiters = delimiters

        syntaxRules = [
            CommentRule(),
            TripleDoubleStringRule(),
            TripleSingleStringRule(),
            SingleLineStringRule(),
            SingleQuoteStringRule(),
            FStringRule(),
            NumberRule(),
            TypeRule(),
            CallRule(),
            KeywordRule()
        ]
    }

    public func isDelimiter(_ delimiterA: Character,
                            mergableWith delimiterB: Character) -> Bool {
        switch (delimiterA, delimiterB) {
        case ("#", _):
            return true
        case (".", _):
            return false
        case ("(", _):
            return false
        case (")", _):
            return false
        case ("[", _), ("]", _):
            return false
        case ("{", _), ("}", _):
            return false
        case ("\"", _):
            return delimiterB == "\""
        case ("'", _):
            return delimiterB == "'"
        default:
            return true
        }
    }
}

private extension PythonGrammar {
    static let keywords: Set<String> = [
        "False", "None", "True",
        "and", "as", "assert", "async", "await",
        "break", "class", "continue",
        "def", "del", "elif", "else", "except",
        "finally", "for", "from",
        "global", "if", "import", "in", "is",
        "lambda", "nonlocal", "not",
        "or", "pass", "raise", "return",
        "try", "while", "with", "yield"
    ]

    static let declarationKeywords: Set<String> = [
        "class", "def", "async", "import", "from", "with",
        "except", "elif", "else", "finally", "for", "if",
        "try", "while", "lambda", "match", "case"
    ]

    struct CommentRule: SyntaxRule {
        var tokenType: TokenType { return .comment }

        func matches(_ segment: Segment) -> Bool {
            if segment.tokens.current.hasPrefix("#") {
                return true
            }
            if segment.tokens.onSameLine.contains(anyOf: "#") {
                return true
            }
            return false
        }
    }

    struct TripleDoubleStringRule: SyntaxRule {
        var tokenType: TokenType { return .string }

        func matches(_ segment: Segment) -> Bool {
            let start = "\"\"\""
            let end = "\"\"\""
            if segment.tokens.current == start || segment.tokens.current == end {
                return true
            }
            let startCount = segment.tokens.count(of: start)
            let endCount = segment.tokens.count(of: end)
            return startCount != endCount
        }
    }

    struct TripleSingleStringRule: SyntaxRule {
        var tokenType: TokenType { return .string }

        func matches(_ segment: Segment) -> Bool {
            let start = "'''"
            let end = "'''"
            if segment.tokens.current == start || segment.tokens.current == end {
                return true
            }
            let startCount = segment.tokens.count(of: start)
            let endCount = segment.tokens.count(of: end)
            return startCount != endCount
        }
    }

    struct FStringRule: SyntaxRule {
        let fstringPrefixes: Set<String> = ["f\"", "f'", "F\"", "F'"]
        var tokenType: TokenType { return .string }

        func matches(_ segment: Segment) -> Bool {
            for prefix in fstringPrefixes {
                if segment.tokens.current.hasPrefix(prefix) &&
                   segment.tokens.current.hasSuffix(prefix.last.map(String.init) ?? "") {
                    return true
                }
                if segment.isWithinStringLiteral(withStart: prefix, end: String(prefix.last!)) {
                    return true
                }
            }
            return false
        }
    }

    struct SingleLineStringRule: SyntaxRule {
        var tokenType: TokenType { return .string }

        func matches(_ segment: Segment) -> Bool {
            if segment.tokens.current.hasPrefix("\"") &&
               segment.tokens.current.hasSuffix("\"") &&
               !segment.tokens.current.hasPrefix("\"\"\"") {
                return true
            }
            guard segment.isWithinStringLiteral(withStart: "\"", end: "\"") else {
                return false
            }
            guard segment.tokens.count(of: "\"\"\"").isEven else {
                return false
            }
            return true
        }
    }

    struct SingleQuoteStringRule: SyntaxRule {
        var tokenType: TokenType { return .string }

        func matches(_ segment: Segment) -> Bool {
            if segment.tokens.current.hasPrefix("'") &&
               segment.tokens.current.hasSuffix("'") &&
               !segment.tokens.current.hasPrefix("'''") {
                return true
            }
            guard segment.isWithinStringLiteral(withStart: "'", end: "'") else {
                return false
            }
            guard segment.tokens.count(of: "'''").isEven else {
                return false
            }
            return true
        }
    }

    struct NumberRule: SyntaxRule {
        var tokenType: TokenType { return .number }

        func matches(_ segment: Segment) -> Bool {
            if segment.tokens.current.removing("_").isNumber {
                return true
            }
            // Handle hex, binary, octal (0x, 0b, 0o prefixes)
            if segment.tokens.current.hasPrefix("0x") || 
               segment.tokens.current.hasPrefix("0X") ||
               segment.tokens.current.hasPrefix("0b") ||
               segment.tokens.current.hasPrefix("0B") ||
               segment.tokens.current.hasPrefix("0o") ||
               segment.tokens.current.hasPrefix("0O") {
                return segment.tokens.current.count > 2
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

    struct CallRule: SyntaxRule {
        var tokenType: TokenType { return .call }

        func matches(_ segment: Segment) -> Bool {
            let token = segment.tokens.current.trimmingCharacters(
                in: CharacterSet(charactersIn: "_")
            )
            guard token.startsWithLetter else {
                return false
            }
            guard !keywords.contains(segment.tokens.current) else {
                return false
            }
            if let previousToken = segment.tokens.previous {
                guard !declarationKeywords.contains(previousToken) else {
                    return false
                }
                guard previousToken != "." else {
                    return false
                }
            }
            guard segment.trailingWhitespace == nil else {
                guard segment.tokens.next == "(" else {
                    return false
                }
                return true
            }
            return segment.tokens.next?.starts(with: "(") ?? false
        }
    }

    struct KeywordRule: SyntaxRule {
        var tokenType: TokenType { return .keyword }

        func matches(_ segment: Segment) -> Bool {
            guard keywords.contains(segment.tokens.current) else {
                return false
            }
            // Don't highlight keywords used as parameter default values
            if segment.tokens.previous == "=" && !declarationKeywords.contains(segment.tokens.current) {
                return false
            }
            // `from` and `import` after `from` should highlight
            if segment.tokens.current == "import" && segment.tokens.previous != "from" {
                return true
            }
            return true
        }
    }

    struct TypeRule: SyntaxRule {
        var tokenType: TokenType { return .type }

        func matches(_ segment: Segment) -> Bool {
            if let previousToken = segment.tokens.previous {
                guard !previousToken.isAny(of: declarationKeywords) else {
                    return false
                }
                // Don't highlight when used as a function call
                guard previousToken != "." else {
                    return false
                }
            }
            let token = segment.tokens.current.trimmingCharacters(
                in: CharacterSet(charactersIn: "_")
            )
            guard token.isCapitalized else {
                return false
            }
            // Make sure it's not followed by `(`
            if let next = segment.tokens.next, next.hasPrefix("(") {
                return false
            }
            return true
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
        var previousToken: String?
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
            previousToken = token
        }
        return markerCounts.start != markerCounts.end
    }
}
