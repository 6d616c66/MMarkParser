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
    ///   - containerWidth: Available text width for layout.
    /// - Returns: A fully styled NSAttributedString ready for display.
    /// - Throws: ParseError if parsing fails.
    @available(iOS 15.0, *)
    public static func parse(
        markdown: String,
        configuration: MMarkStyleConfiguration = .defaultStyle,
        containerWidth: CGFloat
    ) throws -> NSAttributedString {
        let parser = CMarkParser()
        return try parser.parse(markdown, configuration: configuration, containerWidth: containerWidth)
    }
}

// MARK: - Convenience Extension

@available(iOS 15.0, *)
public extension String {
    /// Parse the receiver as Markdown and return an NSAttributedString.
    func parseMarkdown(
        configuration: MMarkStyleConfiguration = .defaultStyle,
        containerWidth: CGFloat
    ) -> NSAttributedString {
        return (try? MMarkParser.parse(markdown: self, configuration: configuration, containerWidth: containerWidth))
            ?? NSAttributedString(string: self)
    }
}
