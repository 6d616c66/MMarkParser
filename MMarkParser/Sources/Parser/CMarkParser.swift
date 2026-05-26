import Foundation
import UIKit

/// Markdown parser powered by md4c's SAX-style callback API.
@available(iOS 15.0, *)
public final class CMarkParser: @unchecked Sendable {
    public enum ParseError: Error {
        case invalidInput
        case parsingFailed
        case styleConversionFailed
    }

    public struct ParseOptions: OptionSet, Sendable {
        public let rawValue: UInt32

        public init(rawValue: UInt32) {
            self.rawValue = rawValue
        }

        /// Default options
        public static let `default` = ParseOptions(rawValue: 0)

        /// Enable GFM table support
        public static let table = ParseOptions(rawValue: MD_FLAG_TABLES)

        /// Enable GFM strikethrough
        public static let strikethrough = ParseOptions(rawValue: MD_FLAG_STRIKETHROUGH)

        /// Enable GFM task lists
        public static let taskLists = ParseOptions(rawValue: MD_FLAG_TASKLISTS)

        /// Enable GFM autolinks (URL, email, www without <> delimiters)
        public static let autolinks = ParseOptions(rawValue: MD_FLAG_PERMISSIVEAUTOLINKS)

        /// Enable LaTeX math spans ($...$, $$...$$)
        public static let latexMath = ParseOptions(rawValue: MD_FLAG_LATEXMATHSPANS)

        /// Enable GFM footnotes (from md4c fork)
        public static let footnotes = ParseOptions(rawValue: MD_FLAG_FOOTNOTES)

        /// Enable hard line breaks
        public static let hardBreaks = ParseOptions(rawValue: MD_FLAG_HARD_SOFT_BREAKS)

        /// All GFM extensions compatible with md4c
        public static let gfm: ParseOptions = [.table, .strikethrough, .taskLists, .autolinks, .latexMath, .footnotes]
    }

    private let options: ParseOptions

    public init(options: ParseOptions = .gfm) {
        self.options = options
    }

    /// Parse Markdown to NSAttributedString
    public func parse(_ markdown: String, configuration: MMarkStyleConfiguration = .defaultStyle) throws -> NSAttributedString {
        guard !markdown.isEmpty else {
            return NSAttributedString()
        }

        guard let result = MMarkParserWrapper.markdown(toAttributedString: markdown, options: options.rawValue, configuration: configuration) else {
            throw ParseError.parsingFailed
        }

        return result
    }
}

// MARK: - md4c Flag Constants

private let MD_FLAG_TABLES: UInt32 = 0x100
private let MD_FLAG_STRIKETHROUGH: UInt32 = 0x200
private let MD_FLAG_PERMISSIVEURLAUTOLINKS: UInt32 = 0x4
private let MD_FLAG_PERMISSIVEEMAILAUTOLINKS: UInt32 = 0x8
private let MD_FLAG_PERMISSIVEWWWAUTOLINKS: UInt32 = 0x400
private let MD_FLAG_PERMISSIVEAUTOLINKS: UInt32 = MD_FLAG_PERMISSIVEEMAILAUTOLINKS | MD_FLAG_PERMISSIVEURLAUTOLINKS | MD_FLAG_PERMISSIVEWWWAUTOLINKS
private let MD_FLAG_TASKLISTS: UInt32 = 0x800
private let MD_FLAG_LATEXMATHSPANS: UInt32 = 0x1000
private let MD_FLAG_FOOTNOTES: UInt32 = 0x100000
private let MD_FLAG_HARD_SOFT_BREAKS: UInt32 = 0x8000
