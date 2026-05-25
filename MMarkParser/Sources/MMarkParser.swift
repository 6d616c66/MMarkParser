import Foundation
import UIKit

/// iOS Markdown parsing and rendering engine powered by md4c and TextKit 2.
public enum MMarkParser {
    /// The default style configuration (GFM defaults).
    public static var defaultStyle: MMarkStyleConfiguration {
        return .defaultStyle
    }

    /// Parse a Markdown string into an NSAttributedString.
    /// - Parameters:
    ///   - markdown: The Markdown source text.
    ///   - configuration: Style configuration; defaults to `.defaultStyle`.
    /// - Returns: A fully styled NSAttributedString ready for display.
    @MainActor @available(iOS 15.0, *)
    public static func parse(
        markdown: String,
        configuration: MMarkStyleConfiguration = .defaultStyle
    ) -> NSAttributedString {
        let parser = CMarkParser()
        do {
            return try parser.parse(markdown, configuration: configuration)
        } catch {
            return NSAttributedString(string: markdown)
        }
    }
}

// MARK: - Convenience Extension

@available(iOS 15.0, *)
public extension String {
    /// Parse the receiver as Markdown and return an NSAttributedString.
    @MainActor func parseMarkdown(
        configuration: MMarkStyleConfiguration = .defaultStyle
    ) -> NSAttributedString {
        return MMarkParser.parse(markdown: self, configuration: configuration)
    }
}
