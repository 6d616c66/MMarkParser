import Foundation
import UIKit

/// Markdown 解析器 - 使用 cmark-gfm 直接节点遍历
@available(iOS 15.0, *)
public final class CMarkParser {
    public enum ParseError: Error {
        case invalidInput
        case parsingFailed
        case styleConversionFailed
    }

    public struct ParseOptions: OptionSet {
        public let rawValue: Int32

        public init(rawValue: Int32) {
            self.rawValue = rawValue
        }

        /// Default options
        public static let `default` = ParseOptions(rawValue: 0)

        /// Enable smart quotes
        public static let smartQuotes = ParseOptions(rawValue: CMARK_OPT_SMART_QUOTES)

        /// Enable smart dashes
        public static let smartDashes = ParseOptions(rawValue: CMARK_OPT_SMART_DASHES)

        /// Enable smart ellipsis
        public static let smartEllipsis = ParseOptions(rawValue: CMARK_OPT_SMART_ELLIPSIS)

        /// Enable hard breaks
        public static let hardBreaks = ParseOptions(rawValue: CMARK_OPT_HARDBREAKS)

        /// Enable safe mode (default)
        public static let safe = ParseOptions(rawValue: CMARK_OPT_SAFE)

        /// Disable safe mode
        public static let unsafe = ParseOptions(rawValue: CMARK_OPT_UNSAFE)

        /// Validate UTF-8
        public static let validateUTF8 = ParseOptions(rawValue: CMARK_OPT_VALIDATE_UTF8)

        /// Enable GFM table support
        public static let table = ParseOptions(rawValue: CMARK_OPT_TABLE)

        /// Enable GFM strikethrough
        public static let strikethrough = ParseOptions(rawValue: CMARK_OPT_STRIKETHROUGH)

        /// Enable GFM task lists
        public static let taskLists = ParseOptions(rawValue: CMARK_OPT_TASKLISTS)

        /// Enable GFM autolinks
        public static let autolinks = ParseOptions(rawValue: CMARK_OPT_AUTOLINK)

        /// Enable GFM footnotes
        public static let footnotes = ParseOptions(rawValue: CMARK_OPT_FOOTNOTES)

        /// All GFM extensions
        public static let gfm: ParseOptions = [.table, .strikethrough, .taskLists, .autolinks, .footnotes, .safe]
    }

    private let options: ParseOptions

    public init(options: ParseOptions = .gfm) {
        self.options = options
    }

    /// 解析 Markdown 为 NSAttributedString
    public func parse(_ markdown: String, configuration: MMarkStyleConfiguration = .defaultStyle) throws -> NSAttributedString {
        guard !markdown.isEmpty else {
            return NSAttributedString()
        }

        // Call Swift wrapper for direct node traversal
        guard let result = MMarkParserWrapper.markdown(toAttributedString: markdown, options: options.rawValue, configuration: configuration) else {
            throw ParseError.parsingFailed
        }

        return result
    }
}

// MARK: - C API Constants

private let CMARK_OPT_SMART_QUOTES: Int32 = 1 << 0
private let CMARK_OPT_SMART_DASHES: Int32 = 1 << 1
private let CMARK_OPT_SMART_ELLIPSIS: Int32 = 1 << 2
private let CMARK_OPT_HARDBREAKS: Int32 = 1 << 3
private let CMARK_OPT_SAFE: Int32 = 1 << 4
private let CMARK_OPT_UNSAFE: Int32 = 1 << 5
private let CMARK_OPT_VALIDATE_UTF8: Int32 = 1 << 6
private let CMARK_OPT_TABLE: Int32 = 1 << 7
private let CMARK_OPT_STRIKETHROUGH: Int32 = 1 << 8
private let CMARK_OPT_AUTOLINK: Int32 = 1 << 9
private let CMARK_OPT_TASKLISTS: Int32 = 1 << 10
private let CMARK_OPT_FOOTNOTES: Int32 = 1 << 13
