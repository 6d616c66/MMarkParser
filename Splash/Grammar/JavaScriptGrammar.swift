/**
 *  Splash
 *  Copyright (c) John Sundell 2018
 *  MIT license - see LICENSE.md
 */

import Foundation

/// Grammar for JavaScript and TypeScript. Covers JS/ES6+ keywords,
/// JSX template expressions, comments, strings (including template
/// literals), numbers, function calls, and type names.
public struct JavaScriptGrammar: Grammar {
    public var delimiters: CharacterSet
    public var syntaxRules: [SyntaxRule]

    public init() {
        var delimiters = CharacterSet.alphanumerics.inverted
        delimiters.remove("_")
        delimiters.remove("\"")
        delimiters.remove("'")
        delimiters.remove("`")
        delimiters.remove("$")
        delimiters.remove("#")
        delimiters.remove("@")
        delimiters.remove(".")
        self.delimiters = delimiters

        syntaxRules = [
            CommentRule(),
            TemplateLiteralRule(),
            SingleLineStringRule(),
            SingleQuoteStringRule(),
            RegexRule(),
            NumberRule(),
            TypeRule(),
            CallRule(),
            DecoratorRule(),
            JSXTagRule(),
            KeywordRule()
        ]
    }

    public func isDelimiter(_ delimiterA: Character,
                            mergableWith delimiterB: Character) -> Bool {
        switch (delimiterA, delimiterB) {
        case ("/", "/"), ("/", "*"), ("*", "/"):
            return true
        case ("/", _):
            return false
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
        case ("<", _), (">", _):
            return delimiterA == delimiterB
        default:
            return true
        }
    }
}

private extension JavaScriptGrammar {
    static let keywords: Set<String> = [
        "async", "await", "break", "case", "catch", "class", "const", "continue",
        "debugger", "default", "delete", "do", "else", "export", "extends",
        "finally", "for", "function", "if", "import", "in", "instanceof",
        "let", "new", "of", "return", "static", "super", "switch", "this",
        "throw", "try", "typeof", "var", "void", "while", "with", "yield",
        // Literals
        "true", "false", "null", "undefined", "NaN", "Infinity",
        // TypeScript
        "interface", "type", "enum", "implements", "readonly", "abstract",
        "private", "protected", "public", "declare", "namespace", "module",
        "as", "any", "boolean", "number", "string", "symbol", "void",
        "never", "unknown", "object", "keyof", "infer", "satisfies",
        "get", "set", "from"
    ]

    static let declarationKeywords: Set<String> = [
        "function", "class", "const", "let", "var", "async", "interface",
        "type", "enum", "import", "export", "declare", "namespace",
        "module", "abstract", "get", "set", "using"
    ]

    struct CommentRule: SyntaxRule {
        var tokenType: TokenType { return .comment }

        func matches(_ segment: Segment) -> Bool {
            if segment.tokens.current.hasPrefix("//") {
                return true
            }
            if segment.tokens.current.isAny(of: "/*", "/**", "*/") {
                return true
            }
            if segment.tokens.onSameLine.contains(anyOf: "//", "///") {
                return true
            }
            let multiLineStartCount = segment.tokens.count(of: "/*") +
                                      segment.tokens.count(of: "/**")
            return multiLineStartCount != segment.tokens.count(of: "*/")
        }
    }

    struct TemplateLiteralRule: SyntaxRule {
        var tokenType: TokenType { return .string }

        func matches(_ segment: Segment) -> Bool {
            let start = "`"
            if segment.tokens.current == "`" ||
               segment.tokens.current.hasPrefix("`") ||
               segment.tokens.current.hasSuffix("`") {
                return true
            }
            let startCount = segment.tokens.count(of: "`")
            return !startCount.isEven
        }
    }

    struct SingleLineStringRule: SyntaxRule {
        var tokenType: TokenType { return .string }

        func matches(_ segment: Segment) -> Bool {
            if segment.tokens.current.hasPrefix("\"") &&
               segment.tokens.current.hasSuffix("\"") {
                return true
            }
            guard segment.isWithinStringLiteral(withStart: "\"", end: "\"") else {
                return false
            }
            return true
        }
    }

    struct SingleQuoteStringRule: SyntaxRule {
        var tokenType: TokenType { return .string }

        func matches(_ segment: Segment) -> Bool {
            if segment.tokens.current.hasPrefix("'") &&
               segment.tokens.current.hasSuffix("'") {
                return true
            }
            guard segment.isWithinStringLiteral(withStart: "'", end: "'") else {
                return false
            }
            return true
        }
    }

    struct RegexRule: SyntaxRule {
        var tokenType: TokenType { return .custom("regexp") }

        func matches(_ segment: Segment) -> Bool {
            guard segment.tokens.current.hasPrefix("/") &&
                  segment.tokens.current.hasSuffix("/") else {
                return false
            }
            guard segment.tokens.current.count > 1 else {
                return false
            }
            // Avoid matching comments and division operators
            guard !segment.tokens.current.hasPrefix("//") else {
                return false
            }
            guard let previous = segment.tokens.previous else {
                return false
            }
            let operators: Set<String> = ["=", "(", "[", "{", ":", ";", ",",
                                           "return", "case", "=>", "&&", "||",
                                           "!", "?", "...", "&", "|", "~", "^",
                                           "%", "*", "/", "+", "-"]
            guard operators.contains(previous) else {
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
            // Handle hex/binary/octal
            if segment.tokens.current.hasPrefix("0x") ||
               segment.tokens.current.hasPrefix("0b") ||
               segment.tokens.current.hasPrefix("0o") {
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

    struct DecoratorRule: SyntaxRule {
        var tokenType: TokenType { return .keyword }

        func matches(_ segment: Segment) -> Bool {
            if segment.tokens.current.hasPrefix("@") {
                return true
            }
            if segment.tokens.previous == "." {
                let suffix = segment.tokens.onSameLine.suffix(2)
                guard suffix.count == 2 else { return false }
                return suffix.first?.hasPrefix("@") ?? false
            }
            return false
        }
    }

    struct JSXTagRule: SyntaxRule {
        var tokenType: TokenType { return .type }

        func matches(_ segment: Segment) -> Bool {
            let token = segment.tokens.current
            // Match HTML/JSX tags: <div>, </div>, <Component>
            guard token.hasPrefix("<") || token.hasPrefix("</") else {
                return false
            }
            let stripped = token
                .replacingOccurrences(of: "<", with: "")
                .replacingOccurrences(of: "/", with: "")
                .replacingOccurrences(of: ">", with: "")
            guard !stripped.isEmpty else { return false }
            return true
        }
    }

    struct CallRule: SyntaxRule {
        var tokenType: TokenType { return .call }

        func matches(_ segment: Segment) -> Bool {
            let token = segment.tokens.current.trimmingCharacters(
                in: CharacterSet(charactersIn: "_")
            )
            guard token.startsWithLetter || token.starts(with: "$") else {
                return false
            }
            guard !keywords.contains(segment.tokens.current) else {
                return false
            }
            if let previousToken = segment.tokens.previous {
                guard !declarationKeywords.contains(previousToken) else {
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
            // Don't highlight when after `function`, `class` declaration keywords
            if segment.tokens.current == "async" {
                if segment.tokens.next == "function" || segment.tokens.next == "=>" {
                    return true
                }
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
            // Exclude common JS built-ins that are capitalized
            if token == "Array" || token == "Object" || token == "String" ||
               token == "Number" || token == "Boolean" || token == "Symbol" ||
               token == "Function" || token == "Promise" || token == "Map" ||
               token == "Set" || token == "WeakMap" || token == "WeakSet" ||
               token == "Error" || token == "Date" || token == "RegExp" ||
               token == "Buffer" || token == "BigInt" {
                return true
            }
            // Avoid function calls
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
