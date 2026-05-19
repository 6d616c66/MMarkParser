import Foundation

/// Preprocesses markdown text to extract math expressions ($...$, $$...$$)
/// and replace them with UUID placeholders before cmark-gfm parsing.
/// This avoids needing to modify the cmark-gfm C source code to add a math extension.
@available(iOS 15.0, *)
public struct MMarkMathPreprocessor {

    /// Result of preprocessing
    public struct Result {
        public let processedMarkdown: String
        public let inlineMathPlaceholders: [String: String]  // placeholder -> LaTeX
        public let blockMathPlaceholders: [String: String]   // placeholder -> LaTeX

        /// All placeholder strings that may appear in the processed markdown
        public var allPlaceholderStrings: Set<String> {
            Set(inlineMathPlaceholders.keys).union(Set(blockMathPlaceholders.keys))
        }

        /// Lookup the original math expression for a given placeholder
        public func mathExpression(for placeholder: String) -> String? {
            inlineMathPlaceholders[placeholder] ?? blockMathPlaceholders[placeholder]
        }

        /// Whether this placeholder represents block math
        public func isBlockMathPlaceholder(_ placeholder: String) -> Bool {
            blockMathPlaceholders.keys.contains(placeholder)
        }
    }

    // MARK: - Placeholder Format

    /// Placeholder format: MMATHI<UUID>X for inline, MMATHB<UUID>X for block
    /// Uses only alphanumeric characters to avoid cmark-gfm interpreting
    /// special characters (like underscores as emphasis markers).
    private static let inlinePrefix = "MMATHI"
    private static let blockPrefix = "MMATHB"
    private static let codePrefix = "MCODEC"
    private static let placeholderSuffix = "X"

    private static func makeInlinePlaceholder() -> String {
        "\(inlinePrefix)\(UUID().uuidString)\(placeholderSuffix)"
    }

    private static func makeBlockPlaceholder() -> String {
        "\(blockPrefix)\(UUID().uuidString)\(placeholderSuffix)"
    }

    private static func makeCodePlaceholder() -> String {
        "\(codePrefix)\(UUID().uuidString)\(placeholderSuffix)"
    }

    // MARK: - Public API

    /// Preprocess markdown text, extracting math expressions into placeholders.
    /// - Parameter markdown: Raw markdown text
    /// - Returns: Processed result with placeholders and math expression dictionary
    public static func preprocess(_ markdown: String) -> Result {
        var text = markdown
        var inlineMath: [String: String] = [:]
        var blockMath: [String: String] = [:]
        var codePlaceholders: [String: String] = [:]

        // Step 1: Protect fenced code blocks (```...``` and ~~~...~~~)
        text = protectFencedCodeBlocks(text, placeholders: &codePlaceholders)

        // Step 2: Protect inline code (`...`)
        text = protectInlineCode(text, placeholders: &codePlaceholders)

        // Step 3: Extract block math $$...$$ (process before inline math)
        text = extractBlockMath(text, blockMath: &blockMath)

        // Step 4: Extract inline math $...$
        text = extractInlineMath(text, inlineMath: &inlineMath)

        // Step 5: Restore code placeholders to their original content
        for (placeholder, original) in codePlaceholders {
            text = text.replacingOccurrences(of: placeholder, with: original)
        }

        print("[MMarkMathPreprocessor] Found \(inlineMath.count) inline and \(blockMath.count) block math expressions")
        if !inlineMath.isEmpty {
            for (_, latex) in inlineMath {
                print("[MMarkMathPreprocessor] Inline math: \(latex.prefix(80))")
            }
        }
        if !blockMath.isEmpty {
            for (_, latex) in blockMath {
                print("[MMarkMathPreprocessor] Block math: \(latex.prefix(80))")
            }
        }

        return Result(
            processedMarkdown: text,
            inlineMathPlaceholders: inlineMath,
            blockMathPlaceholders: blockMath
        )
    }

    // MARK: - Code Protection

    /// Protect fenced code blocks by replacing them with placeholders.
    /// Matches ```...``` and ~~~...~~~ with matching closing fences.
    private static func protectFencedCodeBlocks(_ text: String, placeholders: inout [String: String]) -> String {
        let pattern = "(?ms)^(`{3,}|~{3,})(?:\\s*.*?)?\\n.*?^\\1\\s*$"
        return replaceMatches(pattern: pattern, in: text, placeholders: &placeholders)
    }

    /// Protect inline code spans by replacing them with placeholders.
    /// Matches `code`, ``code``, etc. with matching delimiter lengths.
    private static func protectInlineCode(_ text: String, placeholders: inout [String: String]) -> String {
        let pattern = "(`+)(.+?)\\1"
        return replaceMatches(pattern: pattern, in: text, placeholders: &placeholders)
    }

    /// Replace all regex matches with code placeholders
    private static func replaceMatches(pattern: String, in text: String, placeholders: inout [String: String]) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return text }
        let nsRange = NSRange(text.startIndex..<text.endIndex, in: text)

        // Collect all match ranges as UTF-16 offset pairs from the original text
        let matches = regex.matches(in: text, range: nsRange)
        typealias OffsetRange = (location: Int, length: Int)
        let ranges: [OffsetRange] = matches.map { ($0.range.location, $0.range.length) }

        // Process in reverse, converting NSRange to Range<String.Index>
        // in the current `result` at each iteration.
        var result = text
        for range in ranges.reversed() {
            guard let swiftRange = rangeFromOffsets(range, in: result) else { continue }
            let original = String(result[swiftRange])
            let placeholder = makeCodePlaceholder()
            placeholders[placeholder] = original
            result.replaceSubrange(swiftRange, with: placeholder)
        }

        return result
    }

    // MARK: - Math Extraction

    /// Extract block math expressions $$...$$ and replace with placeholders.
    private static func extractBlockMath(_ text: String, blockMath: inout [String: String]) -> String {
        // Match $$...$$ with non-greedy content, multiline support
        // (?s) enables dotAll mode so . matches newlines
        // (?<!\\) negative lookbehind for escaped \$
        let pattern = "(?s)(?<!\\\\)\\$\\$(.+?)\\$\\$"
        return extractMath(pattern: pattern, in: text, storage: &blockMath, makePlaceholder: makeBlockPlaceholder)
    }

    /// Extract inline math expressions $...$ and replace with placeholders.
    private static func extractInlineMath(_ text: String, inlineMath: inout [String: String]) -> String {
        // Match $...$ with non-greedy content, single line only (no (?s))
        // (?<!\\) negative lookbehind for escaped \$
        // (?!\$) negative lookahead to avoid matching $$
        let pattern = "(?<!\\\\)\\$(.+?)\\$(?!\\$)"
        return extractMath(pattern: pattern, in: text, storage: &inlineMath, makePlaceholder: makeInlinePlaceholder)
    }

    /// Replace all regex matches with math placeholders
    private static func extractMath(pattern: String, in text: String, storage: inout [String: String], makePlaceholder: () -> String) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return text }
        let nsRange = NSRange(text.startIndex..<text.endIndex, in: text)

        // Collect all match ranges as UTF-16 offset pairs from the original text
        let matches = regex.matches(in: text, range: nsRange)
        typealias OffsetRange = (location: Int, length: Int)
        struct MathMatchOffsets {
            let full: OffsetRange
            let content: OffsetRange
        }
        let matchOffsets: [MathMatchOffsets] = matches.compactMap { match in
            guard match.numberOfRanges >= 2 else { return nil }
            return MathMatchOffsets(
                full: (match.range.location, match.range.length),
                content: (match.range(at: 1).location, match.range(at: 1).length)
            )
        }

        // Process in reverse, converting NSRange to Range<String.Index> in current result
        var result = text
        for offsets in matchOffsets.reversed() {
            guard let fullRange = rangeFromOffsets(offsets.full, in: result) else { continue }
            guard let contentRange = rangeFromOffsets(offsets.content, in: result) else { continue }

            let original = String(result[fullRange])
            let mathContent = String(result[contentRange])
                .trimmingCharacters(in: .whitespacesAndNewlines)

            guard !mathContent.isEmpty else { continue }

            let placeholder = makePlaceholder()
            storage[placeholder] = mathContent
            result.replaceSubrange(fullRange, with: placeholder)
        }

        return result
    }

    /// Convert UTF-16 offset pair to Range<String.Index> with fallback.
    private static func rangeFromOffsets(_ offsets: (location: Int, length: Int), in text: String) -> Range<String.Index>? {
        if let r = Range(NSRange(location: offsets.location, length: offsets.length), in: text) {
            return r
        }
        // Fallback: use UTF-16 offset-based substring extraction
        let utf16 = text.utf16
        guard let start = utf16.index(utf16.startIndex, offsetBy: offsets.location, limitedBy: utf16.endIndex),
              let end = utf16.index(utf16.startIndex, offsetBy: offsets.location + offsets.length, limitedBy: utf16.endIndex),
              start < end,
              let ss = start.samePosition(in: text),
              let ee = end.samePosition(in: text) else { return nil }
        return ss..<ee
    }
}