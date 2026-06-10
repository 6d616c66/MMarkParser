/**
 *  Splash
 *  Copyright (c) John Sundell 2018
 *  MIT license - see LICENSE.md
 */

import Foundation

/// Grammar for HTML/XML. Handles tags, attributes, string values,
/// comments, and DOCTYPE/processing instructions.
public struct HTMLGrammar: Grammar {
    public var delimiters: CharacterSet
    public var syntaxRules: [SyntaxRule]

    public init() {
        var delimiters = CharacterSet.alphanumerics.inverted
        delimiters.remove("_")
        delimiters.remove("\"")
        delimiters.remove("'")
        delimiters.remove("-")
        delimiters.remove(":")
        delimiters.remove(".")
        delimiters.remove("/")
        self.delimiters = delimiters

        syntaxRules = [
            CommentRule(),
            DocTypeRule(),
            PreprocessorRule(),
            StringRule(),
            SingleQuoteStringRule(),
            TagNameRule(),
            ClosingTagRule(),
            AttributeRule(),
            EntityRule(),
            ValueRule()
        ]
    }

    public func isDelimiter(_ delimiterA: Character,
                            mergableWith delimiterB: Character) -> Bool {
        switch (delimiterA, delimiterB) {
        case ("<", _):
            return delimiterB == "/" || delimiterB == "!" || delimiterB == "?"
        case ("/", _):
            return delimiterA == delimiterB
        case ("-", _):
            return delimiterB == "-"
        case (":", _):
            return delimiterB == ":"
        case (".", _):
            return delimiterB == "/"
        default:
            return true
        }
    }
}

private extension HTMLGrammar {
    static let htmlTags: Set<String> = [
        "html", "head", "body", "div", "span", "p", "a", "img",
        "ul", "ol", "li", "table", "tr", "td", "th", "thead",
        "tbody", "tfoot", "col", "colgroup", "caption",
        "form", "input", "button", "select", "option", "optgroup",
        "textarea", "label", "fieldset", "legend",
        "h1", "h2", "h3", "h4", "h5", "h6",
        "header", "footer", "nav", "main", "section", "article",
        "aside", "figure", "figcaption", "details", "summary",
        "mark", "time", "progress", "meter", "data",
        "link", "meta", "style", "script", "title", "base",
        "br", "hr", "wbr", "iframe", "embed", "object", "param",
        "source", "track", "canvas", "svg", "math",
        "video", "audio", "picture", "map", "area",
        "datalist", "output", "dialog", "slot", "template",
        "blockquote", "q", "cite", "em", "strong", "i", "b",
        "u", "s", "small", "sub", "sup", "code", "pre", "kbd",
        "samp", "var", "abbr", "dfn", "ins", "del",
        "address", "noscript",
        // XML / SVG
        "xml", "xsl", "xslt", "svg", "g", "path", "circle",
        "rect", "line", "polyline", "polygon", "text", "tspan",
        "defs", "use", "clipPath", "mask", "pattern",
        "linearGradient", "radialGradient", "stop"
    ]

    static let attributes: Set<String> = [
        "class", "id", "style", "href", "src", "alt", "title",
        "name", "value", "type", "placeholder", "disabled",
        "readonly", "required", "checked", "selected", "hidden",
        "data-", "aria-", "role", "rel", "target", "download",
        "width", "height", "min", "max", "step", "pattern",
        "autocomplete", "autofocus", "autoplay", "loop",
        "controls", "muted", "poster", "preload",
        "action", "method", "enctype", "accept", "accept-charset",
        "onsubmit", "onclick", "onchange", "oninput",
        "onload", "onerror", "onscroll", "onfocus", "onblur",
        "lang", "dir", "charset", "http-equiv", "content",
        "property", "itemprop", "itemtype", "itemscope",
        "xmlns", "version", "viewBox", "fill", "stroke",
        "d", "cx", "cy", "r", "x", "y", "transform",
        "key", "ref", "onClick", "onChange", "className",
        "colspan", "rowspan", "scope"
    ]

    struct CommentRule: SyntaxRule {
        var tokenType: TokenType { return .comment }

        func matches(_ segment: Segment) -> Bool {
            if segment.tokens.current == "<!--" || segment.tokens.current == "-->" {
                return true
            }
            if segment.tokens.current.hasPrefix("<!--") {
                return true
            }
            if segment.tokens.onSameLine.contains(anyOf: "<!--") {
                if !segment.tokens.onSameLine.contains("-->") {
                    return true
                }
            }
            let startCount = segment.tokens.count(of: "<!--")
            let endCount = segment.tokens.count(of: "-->")
            return startCount != endCount
        }
    }

    struct DocTypeRule: SyntaxRule {
        var tokenType: TokenType { return .keyword }

        func matches(_ segment: Segment) -> Bool {
            return segment.tokens.current == "<!" ||
                   segment.tokens.current == "<!DOCTYPE" ||
                   segment.tokens.current == "DOCTYPE"
        }
    }

    struct PreprocessorRule: SyntaxRule {
        var tokenType: TokenType { return .preprocessing }

        func matches(_ segment: Segment) -> Bool {
            return segment.tokens.current.hasPrefix("<?")
        }
    }

    struct TagNameRule: SyntaxRule {
        var tokenType: TokenType { return .keyword }

        func matches(_ segment: Segment) -> Bool {
            guard htmlTags.contains(segment.tokens.current.lowercased()) else {
                return false
            }
            // Must be after `<` or `</`
            guard let previous = segment.tokens.previous else {
                return false
            }
            return previous == "<" || previous == "</"
        }
    }

    struct ClosingTagRule: SyntaxRule {
        var tokenType: TokenType { return .type }

        func matches(_ segment: Segment) -> Bool {
            guard segment.tokens.current.hasPrefix("</") && segment.tokens.current.hasSuffix(">") else {
                return false
            }
            let tagName = segment.tokens.current
                .replacingOccurrences(of: "</", with: "")
                .replacingOccurrences(of: ">", with: "")
            return htmlTags.contains(tagName.lowercased())
        }
    }

    struct AttributeRule: SyntaxRule {
        var tokenType: TokenType { return .property }

        func matches(_ segment: Segment) -> Bool {
            let token = segment.tokens.current
            guard attributes.contains(token) || attributes.contains(attributeName(from: token)) else {
                return false
            }
            // Must be inside a tag (previous token is a tag name or another attribute)
            guard let previous = segment.tokens.previous else {
                return false
            }
            return htmlTags.contains(previous) || attributes.contains(previous) || previous == ">"
        }

        private func attributeName(from token: String) -> String {
            // For data-* and aria-* attributes
            if token.hasPrefix("data-") || token.hasPrefix("aria-") {
                let parts = token.split(separator: "-", maxSplits: 1, omittingEmptySubsequences: false)
                if parts.count >= 2 {
                    return String(parts[0]) + "-"
                }
            }
            return token
        }
    }

    struct StringRule: SyntaxRule {
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

    /// Highlight HTML entities like &amp; &lt; &gt;
    struct EntityRule: SyntaxRule {
        var tokenType: TokenType { return .custom("entity") }

        func matches(_ segment: Segment) -> Bool {
            let token = segment.tokens.current
            return token.hasPrefix("&") && token.hasSuffix(";") && token.count > 2
        }
    }

    /// Highlight attribute values (text after = sign)
    struct ValueRule: SyntaxRule {
        var tokenType: TokenType { return .string }

        func matches(_ segment: Segment) -> Bool {
            guard segment.tokens.previous == "=" else {
                return false
            }
            // Should be a quoted value
            let token = segment.tokens.current
            return token.hasPrefix("\"") || token.hasPrefix("'")
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