# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

MMarkParser is an iOS Markdown parsing and rendering library that uses:
- **libcmark_gfm** for GFM (GitHub Flavored Markdown) parsing via C API
- **Splash** (bundled in `Sources/Splash/`) for Swift code syntax highlighting
- **TextKit 2** for rendering with NSTextAttachment view providers

## Build Commands

```bash
# Build the Swift package
swift build

# Run tests
swift test

# Run a single test
swift test --filter MMarkParserTests.testHeading

# Build for iOS Simulator (via Xcode)
xcodebuild -scheme MMarkParser -sdk iphonesimulator -configuration Debug build
```

## Architecture

### Parser Pipeline
1. `MMarkParser.parse()` → `CMarkParser.parse()` → `MMarkParserWrapper.markdown(toAttributedString:)`
2. `MMarkParserWrapper` uses libcmark_gfm C API to parse markdown into a node tree
3. Node tree is traversed and converted to `NSAttributedString` with styled attributes

### Key Components
- **`Sources/Parser/CMarkParser.swift`** - Public API wrapper around libcmark-gfm options
- **`Sources/Parser/MMarkParserWrapper.swift`** - Core parsing logic via direct cmark node traversal
- **`Sources/Renderer/MMarkTextKit2Renderer.swift`** - TextKit 2 integration for UITextView
- **`Sources/Renderer/Attachments/`** - NSTextAttachment subclasses with view providers for code blocks, tables, and images
- **`Sources/Splash/`** - Bundled syntax highlighter (from John Sundell) used for code block highlighting

### Code Block Rendering
Code blocks use `MMarkCodeBlockAttachment` with `MMarkCodeBlockViewProvider`. The `highlightedCode(language:code:configuration:)` static method uses Splash's `SyntaxHighlighter<AttributedStringOutputFormat>` for syntax highlighting.

## Platform & Dependencies

- **Minimum iOS**: 15.0
- **Dependencies**: libcmark_gfm (CocoaPods), Splash (bundled source)
- **Uses CocoaPods** for the Demo app target