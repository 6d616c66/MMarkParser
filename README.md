# MMarkParser

A Markdown parsing and rendering library for iOS, built on TextKit 2 with full GFM support.

## Features

- **Standard Markdown** — headings, paragraphs, bold, italic, strikethrough, links, images, code
- **GFM Extensions** — tables, task lists, autolinks, strikethrough
- **LaTeX Math** — inline (`$...$`) and block (`$$...$$`) math rendered via iosMath
- **Syntax Highlighting** — code blocks with language-aware highlighting (Swift + generic)
- **Footnotes** — GFM-style footnote references and definitions
- **Nested Blockquotes** — with customizable bar colors and backgrounds
- **Fully Customizable** — fonts, colors, spacing for every element via `MMarkStyleConfiguration`
- **TextKit 2** — modern layout engine, designed for iOS 15+

## Requirements

- iOS 15.0+
- Swift 5.7+
- Xcode 15.0+

## Installation

### Swift Package Manager

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/<your-org>/MMarkParser.git", from: "1.0.0")
]
```

Or in Xcode: File → Add Packages → enter the repo URL.

### CocoaPods

```ruby
pod 'MMarkParser', '~> 1.0.0'
```

MMarkParser depends on:
- [md4c](https://github.com/mity/md4c) — Markdown parsing engine
- [iosMath](https://github.com/kostub/iosMath) — LaTeX math rendering
- [Kingfisher](https://github.com/onevcat/Kingfisher) — remote image loading (for `![](url)` images)

## Quick Start

```swift
import MMarkParser

// Parse markdown to NSAttributedString
let markdown = "# Hello\n\nThis is **Markdown** with $E=mc^2$"
let attributedString = MMarkParser.parse(markdown: markdown)

// Or use the String extension
let attributedString = markdown.parseMarkdown()

// Display in MMarkTextView (handles link taps, blockquote bars, etc.)
let textView = MMarkTextView()
textView.setMarkdown(markdown)
view.addSubview(textView)
```

## Customization

```swift
var config = MMarkStyleConfiguration.defaultStyle

// Customize heading fonts
config.headingStyles[1] = .init(
    font: UIFont.systemFont(ofSize: 32, weight: .bold),
    textColor: .label
)

// Customize code blocks
config.codeBlockStyle = .init(
    font: UIFont.monospacedSystemFont(ofSize: 14, weight: .regular),
    textColor: .white,
    backgroundColor: .darkGray
)

// Customize blockquote appearance
config.blockquoteBorderColor = .systemBlue
config.blockquoteBorderWidth = 4
config.blockquoteBackgroundColor = UIColor.systemBlue.withAlphaComponent(0.05)

let result = MMarkParser.parse(markdown: markdown, configuration: config)
```

See `MMarkStyleConfiguration.swift` for all available options.

## Supported Markdown

| Element | Support |
|---|---|
| Headings (H1–H6) | Full |
| Bold, Italic | Full |
| Strikethrough | GFM |
| Inline Code | Full |
| Code Blocks (fenced) | Full + syntax highlighting |
| Links | Full + delegate |
| Images | Full (remote via Kingfisher) |
| Blockquotes | Full + nesting |
| Ordered Lists | Full |
| Unordered Lists | Full |
| Task Lists | GFM |
| Tables | GFM |
| Horizontal Rules | Full |
| LaTeX Math | `$...$` inline, `$$...$$` block |
| Footnotes | GFM |
| Autolinks | URL, email, www |

## Architecture

```
Sources/
├── MMarkParser.swift              # Public API entry point
├── Parser/
│   ├── CMarkParser.swift          # Parser configuration & options
│   └── MMarkParserWrapper.swift   # md4c SAX callback handler
├── Renderer/
│   ├── MMarkTextView.swift        # TextKit 2 text view
│   ├── MMarkStyleConfiguration.swift  # Style definitions
│   ├── MMarkFontLoader.swift      # KaTeX font registration
│   └── Attachments/               # Custom NSTextAttachment views
│       ├── MMarkCodeBlockAttachment/
│       ├── MMarkImageAttachment/
│       ├── MMarkTableAttachment/
│       ├── MMarkMathBlockAttachment/
│       └── MMarkHorizontalRuleAttachment/
└── Splash/                        # Syntax highlighting (bundled)
```

MMarkParser uses [md4c](https://github.com/mity/md4c) with a SAX-style callback model — parsing walks the Markdown AST and incrementally builds an `NSAttributedString` with custom attributes, attachments, and styles.

##Referenced
MMarkParser referenced the implementations of the following two libraries
https://github.com/zjc19891106/MarkdownDisplayView
https://github.com/antgroup/FluidMarkdown

## License

MMarkParser is available under the MIT license. See the [LICENSE](LICENSE) file for more info.

## Acknowledgments

- [md4c](https://github.com/mity/md4c) — C Markdown parser
- [iosMath](https://github.com/kostub/iosMath) — LaTeX math rendering
- [Kingfisher](https://github.com/onevcat/Kingfisher) — Image downloading
- [Splash](https://github.com/JohnSundell/Splash) — Swift syntax highlighting
