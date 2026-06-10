/**
 *  Splash
 *  Copyright (c) John Sundell 2018
 *  MIT license - see LICENSE.md
 */

import Foundation

/// Grammar for CSS stylesheets. Handles selectors, properties,
/// values, colors, units, pseudo-classes/elements, at-rules, and comments.
public struct CSSGrammar: Grammar {
    public var delimiters: CharacterSet
    public var syntaxRules: [SyntaxRule]

    public init() {
        var delimiters = CharacterSet.alphanumerics.inverted
        delimiters.remove("_")
        delimiters.remove("-")
        delimiters.remove("\"")
        delimiters.remove("'")
        delimiters.remove("#")
        delimiters.remove(".")
        delimiters.remove("@")
        delimiters.remove(":")
        delimiters.remove("%")
        self.delimiters = delimiters

        syntaxRules = [
            CommentRule(),
            StringRule(),
            SingleQuoteStringRule(),
            UrlRule(),
            HexColorRule(),
            NumberRule(),
            PseudoRule(),
            AtRule(),
            SelectorRule(),
            ClassRule(),
            IdRule(),
            ImportantRule(),
            PropertyRule(),
            ValueKeywordRule(),
            UnitRule()
        ]
    }

    public func isDelimiter(_ delimiterA: Character,
                            mergableWith delimiterB: Character) -> Bool {
        switch (delimiterA, delimiterB) {
        case ("/", "*"), ("*", "/"):
            return true
        case ("-", _):
            return delimiterB == "-"
        case (":", _):
            return delimiterA == delimiterB
        case ("#", _):
            return delimiterA == delimiterB
        case ("(", _), (")", _):
            return false
        case ("{", _), ("}", _):
            return false
        case ("[", _), ("]", _):
            return false
        default:
            return true
        }
    }
}

private extension CSSGrammar {
    static let cssProperties: Set<String> = [
        // Layout & Display
        "display", "position", "top", "right", "bottom", "left",
        "float", "clear", "visibility", "overflow", "overflow-x",
        "overflow-y", "clip", "z-index", "isolation",
        // Flexbox
        "flex", "flex-direction", "flex-wrap", "flex-flow",
        "flex-grow", "flex-shrink", "flex-basis", "justify-content",
        "align-items", "align-self", "align-content", "order", "gap",
        "row-gap", "column-gap",
        // Grid
        "grid", "grid-template", "grid-template-columns",
        "grid-template-rows", "grid-template-areas",
        "grid-column", "grid-row", "grid-column-start",
        "grid-column-end", "grid-row-start", "grid-row-end",
        "grid-area", "grid-auto-flow",
        "justify-items", "justify-self", "place-items",
        "place-self", "place-content",
        // Box Model
        "width", "min-width", "max-width",
        "height", "min-height", "max-height",
        "margin", "margin-top", "margin-right", "margin-bottom",
        "margin-left", "padding", "padding-top", "padding-right",
        "padding-bottom", "padding-left",
        "border", "border-top", "border-right", "border-bottom",
        "border-left", "border-width", "border-style", "border-color",
        "border-collapse", "border-spacing",
        "border-radius", "border-top-left-radius",
        "border-top-right-radius", "border-bottom-right-radius",
        "border-bottom-left-radius",
        "border-image", "border-image-source",
        "outline", "outline-width", "outline-style", "outline-color",
        "outline-offset", "box-sizing", "box-shadow",
        // Typography
        "font", "font-family", "font-size", "font-weight",
        "font-style", "font-variant", "font-stretch",
        "line-height", "letter-spacing", "word-spacing",
        "text-align", "text-decoration", "text-transform",
        "text-indent", "text-shadow", "text-overflow",
        "word-break", "word-wrap", "white-space",
        "vertical-align", "direction", "unicode-bidi",
        "font-display", "font-feature-settings",
        "font-kerning", "font-size-adjust",
        "color",
        // Background
        "background", "background-color", "background-image",
        "background-repeat", "background-position",
        "background-size", "background-attachment",
        "background-clip", "background-origin",
        "background-blend-mode",
        // Lists
        "list-style", "list-style-type", "list-style-position",
        "list-style-image",
        // Tables
        "table-layout", "caption-side", "empty-cells",
        // Animation & Transition
        "animation", "animation-name", "animation-duration",
        "animation-timing-function", "animation-delay",
        "animation-iteration-count", "animation-direction",
        "animation-fill-mode", "animation-play-state",
        "transition", "transition-property", "transition-duration",
        "transition-timing-function", "transition-delay",
        "transform", "transform-origin", "transform-style",
        "perspective", "perspective-origin", "backface-visibility",
        "rotate", "scale", "translate",
        // UI
        "cursor", "opacity", "pointer-events", "user-select",
        "resize", "appearance", "accent-color",
        "caret-color", "scroll-behavior", "scroll-margin",
        "scroll-padding", "scroll-snap-type",
        // Filters & Effects
        "filter", "backdrop-filter", "mix-blend-mode",
        "will-change", "contain",
        // Columns
        "columns", "column-count", "column-width",
        "column-gap", "column-rule", "column-span", "column-fill",
        // Content
        "content", "counter-reset", "counter-increment",
        "quotes", "hyphens",
        // Masking & Clipping
        "clip-path", "mask", "mask-image", "mask-size",
        "mask-repeat", "mask-position", "shape-outside",
        // Variables
        "--",
        // Container queries
        "container", "container-type", "container-name",
        // SVG
        "fill", "stroke", "stroke-width", "stroke-linecap",
        "stroke-linejoin", "stroke-dasharray", "stroke-dashoffset",
        "stop-color", "stop-opacity"
    ]

    static let cssValues: Set<String> = [
        // Colors
        "transparent", "currentColor", "inherit", "initial",
        "revert", "unset",
        // Layout
        "block", "inline", "inline-block", "flex", "inline-flex",
        "grid", "inline-grid", "flow-root", "table", "none",
        "relative", "absolute", "fixed", "sticky", "static",
        "visible", "hidden", "scroll", "auto",
        // Flex
        "row", "column", "wrap", "nowrap", "wrap-reverse",
        "start", "end", "center", "space-between", "space-around",
        "space-evenly", "stretch", "baseline",
        // Sizing
        "fit-content", "min-content", "max-content",
        "contain", "cover",
        // Text
        "left", "right", "justify",
        "underline", "overline", "line-through", "blink", "none",
        "uppercase", "lowercase", "capitalize",
        "normal", "bold", "lighter", "bolder",
        "italic", "oblique",
        "serif", "sans-serif", "monospace", "cursive", "fantasy",
        "break-word", "break-all", "keep-all",
        "ellipsis", "clip",
        // Position
        "static", "relative", "absolute", "fixed", "sticky",
        // Repeat
        "repeat", "no-repeat", "repeat-x", "repeat-y",
        "round", "space",
        // Animation
        "ease", "ease-in", "ease-out", "ease-in-out",
        "linear", "step-start", "step-end",
        "infinite", "forwards", "backwards", "both",
        "running", "paused",
        // Other
        "solid", "dashed", "dotted", "double", "groove",
        "ridge", "inset", "outset", "hidden",
        "collapse", "separate",
        "pointer", "grab", "grabbing",
        "all", "child", "descendant",
        "global", "local",
        "optional", "mandatory",
        "progressive", "interleaved",
        // Display
        "flow", "flow-root", "table-row", "table-cell",
        "list-item", "contents"
    ]

    struct CommentRule: SyntaxRule {
        var tokenType: TokenType { return .comment }

        func matches(_ segment: Segment) -> Bool {
            if segment.tokens.current.isAny(of: "/*", "/**", "*/") {
                return true
            }
            let startCount = segment.tokens.count(of: "/*") + segment.tokens.count(of: "/**")
            return startCount != segment.tokens.count(of: "*/")
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

    struct UrlRule: SyntaxRule {
        var tokenType: TokenType { return .string }

        func matches(_ segment: Segment) -> Bool {
            return segment.tokens.current.lowercased().hasPrefix("url(")
        }
    }

    struct HexColorRule: SyntaxRule {
        var tokenType: TokenType { return .number }

        func matches(_ segment: Segment) -> Bool {
            let token = segment.tokens.current
            guard token.hasPrefix("#") else {
                return false
            }
            guard token.count == 4 || token.count == 7 || token.count == 9 else {
                return false
            }
            let hex = token.dropFirst()
            return hex.allSatisfy { $0.isHexDigit }
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

    struct PseudoRule: SyntaxRule {
        var tokenType: TokenType { return .keyword }

        func matches(_ segment: Segment) -> Bool {
            let token = segment.tokens.current
            return token.hasPrefix(":") || token.hasPrefix("::")
        }
    }

    struct AtRule: SyntaxRule {
        var tokenType: TokenType { return .preprocessing }

        func matches(_ segment: Segment) -> Bool {
            return segment.tokens.current.hasPrefix("@")
        }
    }

    /// Highlight tag/element selectors
    struct SelectorRule: SyntaxRule {
        var tokenType: TokenType { return .type }

        func matches(_ segment: Segment) -> Bool {
            let token = segment.tokens.current
            guard !token.isEmpty else { return false }
            // Simple element selectors (div, body, etc.)
            guard token.startsWithLetter else { return false }
            guard !cssProperties.contains(token) else { return false }
            guard !cssValues.contains(token) else { return false }
            // Must be right after a selector combinator or at start
            guard let previous = segment.tokens.previous else {
                return true
            }
            let selectorTokens: Set<String> = [",", "{", ">", "+", "~", " "]
            guard !selectorTokens.contains(previous) else {
                return true
            }
            // After `:not(`, `:is(`, etc.
            if previous.hasSuffix("(") {
                return true
            }
            return false
        }
    }

    struct ClassRule: SyntaxRule {
        var tokenType: TokenType { return .property }

        func matches(_ segment: Segment) -> Bool {
            return segment.tokens.current.hasPrefix(".")
        }
    }

    struct IdRule: SyntaxRule {
        var tokenType: TokenType { return .keyword }

        func matches(_ segment: Segment) -> Bool {
            let token = segment.tokens.current
            guard token.hasPrefix("#") && !token.dropFirst().allSatisfy(\.isHexDigit) else {
                return false
            }
            // Not a hex color
            guard token.count != 4 && token.count != 7 && token.count != 9 else {
                return false
            }
            return true
        }
    }

    struct ImportantRule: SyntaxRule {
        var tokenType: TokenType { return .keyword }

        func matches(_ segment: Segment) -> Bool {
            return segment.tokens.current == "!important"
        }
    }

    struct PropertyRule: SyntaxRule {
        var tokenType: TokenType { return .property }

        func matches(_ segment: Segment) -> Bool {
            let token = segment.tokens.current
            guard cssProperties.contains(token) else {
                return false
            }
            // Property is followed by `:`
            guard let next = segment.tokens.next else {
                return false
            }
            return next == ":"
        }
    }

    struct ValueKeywordRule: SyntaxRule {
        var tokenType: TokenType { return .keyword }

        func matches(_ segment: Segment) -> Bool {
            return cssValues.contains(segment.tokens.current)
        }
    }

    struct UnitRule: SyntaxRule {
        var tokenType: TokenType { return .number }

        func matches(_ segment: Segment) -> Bool {
            let token = segment.tokens.current
            let units = ["px", "em", "rem", "vh", "vw", "vmin", "vmax",
                         "%", "deg", "rad", "s", "ms", "pt", "pc",
                         "cm", "mm", "in", "ch", "ex", "lh", "rlh",
                         "dpi", "dpcm", "dppx", "fr", "q", "svw", "svh",
                         "lvw", "lvh", "dvw", "dvh", "cqw", "cqh", "cqi",
                         "cqb", "cqmin", "cqmax"]
            for unit in units {
                if token.hasSuffix(unit) {
                    let prefix = String(token.dropLast(unit.count))
                    if prefix.isNumber || prefix == "" {
                        return true
                    }
                }
            }
            return false
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