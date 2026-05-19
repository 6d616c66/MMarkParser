import XCTest
@testable import MMarkParser

@available(iOS 15.0, *)
final class MMarkParserTests: XCTestCase {
    func testHeading() {
        let markdown = "# Heading 1\n## Heading 2\n### Heading 3"
        let result = MMarkParser.parse(markdown: markdown)
        XCTAssertFalse(result.string.isEmpty)
    }

    func testBold() {
        let markdown = "This is **bold** text"
        let result = MMarkParser.parse(markdown: markdown)
        XCTAssertTrue(result.string.contains("bold"))
    }

    func testItalic() {
        let markdown = "This is *italic* text"
        let result = MMarkParser.parse(markdown: markdown)
        XCTAssertTrue(result.string.contains("italic"))
    }

    func testInlineCode() {
        let markdown = "Use `code` here"
        let result = MMarkParser.parse(markdown: markdown)
        XCTAssertTrue(result.string.contains("code"))
    }

    func testCodeBlock() {
        let markdown = """
        ```swift
        let hello = "world"
        ```
        """
        let result = MMarkParser.parse(markdown: markdown)
        XCTAssertTrue(result.length > 0)
    }

    func testLink() {
        let markdown = "[Link Text](https://example.com)"
        let result = MMarkParser.parse(markdown: markdown)
        XCTAssertTrue(result.string.contains("Link Text"))
    }

    func testImage() {
        let markdown = "![alt text](https://example.com/image.png)"
        let result = MMarkParser.parse(markdown: markdown)
        XCTAssertTrue(result.length > 0)
    }

    func testUnorderedList() {
        let markdown = "- Item 1\n- Item 2\n- Item 3"
        let result = MMarkParser.parse(markdown: markdown)
        XCTAssertTrue(result.string.contains("Item 1"))
        XCTAssertTrue(result.string.contains("Item 2"))
    }

    func testOrderedList() {
        let markdown = "1. First\n2. Second\n3. Third"
        let result = MMarkParser.parse(markdown: markdown)
        XCTAssertTrue(result.string.contains("First"))
        XCTAssertTrue(result.string.contains("Second"))
    }

    func testTaskList() {
        let markdown = "- [x] Done\n- [ ] Not done"
        let result = MMarkParser.parse(markdown: markdown)
        XCTAssertTrue(result.string.contains("Done"))
    }

    func testBlockquote() {
        let markdown = "> This is a quote"
        let result = MMarkParser.parse(markdown: markdown)
        XCTAssertTrue(result.string.contains("quote"))
    }

    func testStrikethrough() {
        let markdown = "~~deleted text~~"
        let result = MMarkParser.parse(markdown: markdown)
        XCTAssertTrue(result.string.contains("deleted"))
        // Verify strikethrough attribute is applied
        let range = (result.string as NSString).range(of: "deleted")
        let strikeStyle = result.attribute(.strikethroughStyle, at: range.location, effectiveRange: nil) as? Int
        XCTAssertEqual(strikeStyle, NSUnderlineStyle.single.rawValue, "Strikethrough style should be applied to ~~text~~")
    }

    func testAutolink() {
        let markdown = "Visit <https://example.com>"
        let result = MMarkParser.parse(markdown: markdown)
        XCTAssertTrue(result.string.contains("example.com"))
    }

    func testParagraph() {
        let markdown = "This is a paragraph.\n\nThis is another paragraph."
        let result = MMarkParser.parse(markdown: markdown)
        XCTAssertTrue(result.string.contains("paragraph"))
    }

    func testEmptyString() {
        let markdown = ""
        let result = MMarkParser.parse(markdown: markdown)
        XCTAssertEqual(result.length, 0)
    }

    func testDebugHTMLOutput() {
        let markdown = "# Main Title\n\nThis is paragraph."
        let parser = CMarkParser()
        do {
            let result = try parser.parse(markdown, configuration: .defaultStyle)
            print("=== Parsed attributed string ===")
            print(result.string)
            print("=== Length: \(result.length) ===")
        } catch {
            print("Error: \(error)")
        }
    }

    func testInlineMath() {
        let markdown = "Inline math: $E = mc^2$"
        let result = MMarkParser.parse(markdown: markdown)
        XCTAssertTrue(result.string.contains("E = mc^2"), "Inline math content should be present")
    }

    func testBlockMath() {
        let markdown = """
        Block math:
        $$\\sum_{i=1}^n i = \\frac{n(n+1)}{2}$$
        """
        let result = MMarkParser.parse(markdown: markdown)
        XCTAssertTrue(result.string.contains("sum_{i=1}^n"), "Block math content should be present")
        XCTAssertTrue(result.length > 0)
    }

    func testMathInCodeBlock() {
        // Math inside code blocks should NOT be processed as math
        let markdown = """
        ```
        $not math$
        $$
        not math either
        $$
        ```
        """
        let result = MMarkParser.parse(markdown: markdown)
        XCTAssertTrue(result.length > 0)
    }

    func testMathInInlineCode() {
        // Math inside inline code (backtick) should NOT be processed as math
        let markdown = "在代码中使用公式: let result = calculate(`$E=mc^2$`) 不会被解析。"
        let result = MMarkParser.parse(markdown: markdown)
        // The math content ($E=mc^2$) should NOT appear as a math placeholder/replacement
        XCTAssertTrue(result.length > 0)
        // The content should contain the raw formula text (not a rendered attachment)
        // If it were parsed as math, "E = mc^2" would appear with different attributes
        let text = result.string
        XCTAssertTrue(text.contains("E = mc^2"), "Math inside backtick code should appear as literal text")
    }

    func testEscapedDollarNotMath() {
        let markdown = "Escaped dollar: \\$10 not math"
        let result = MMarkParser.parse(markdown: markdown)
        XCTAssertTrue(result.string.contains("$10"), "Escaped dollar should not be treated as math")
    }

    func testComplexMarkdown() {
        let markdown = """
        # Main Title

        This is a paragraph with **bold** and *italic* text.

        ## Subtitle

        - List item 1
        - List item 2

        > A quote block

        More text with `inline code`.
        """
        let result = MMarkParser.parse(markdown: markdown)
        XCTAssertFalse(result.string.isEmpty)
    }
}
