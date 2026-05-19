import Foundation
import UIKit
import libcmark_gfm
import ObjectiveC
import iosMath

extension NSAttributedString.Key {
    public static let blockquote = NSAttributedString.Key("MMarkBlockquote")
    public static let blockquoteDepth = NSAttributedString.Key("MMarkBlockquoteDepth")
    public static let footnoteRef = NSAttributedString.Key("MMarkFootnoteRef")
    public static let footnoteDef = NSAttributedString.Key("MMarkFootnoteDef")
}

/// Swift wrapper for cmark-gfm - Direct node traversal
@available(iOS 15.0, *)
public final class MMarkParserWrapper {
    
    // MARK: - Internal Types
    
    private struct ProcessingContext {
        let configuration: MMarkStyleConfiguration
        var containerWidth: CGFloat  // 改为 var 以支持在 blockquote 中调整
        var listDepth: Int
        var blockquoteDepth: Int  // 引用嵌套深度
        var currentIndent: CGFloat
        var currentHeadIndent: CGFloat
        var isFirstItemChild: Bool
        var isInsideBlockquote: Bool

        init(configuration: MMarkStyleConfiguration, 
             containerWidth: CGFloat, 
             listDepth: Int = 0,
             blockquoteDepth: Int = 0,
             currentIndent: CGFloat = 0, 
             currentHeadIndent: CGFloat = 0,
             isFirstItemChild: Bool = false,
             isInsideBlockquote: Bool = false) {
            self.configuration = configuration
            self.containerWidth = containerWidth
            self.listDepth = listDepth
            self.blockquoteDepth = blockquoteDepth
            self.currentIndent = currentIndent
            self.currentHeadIndent = currentHeadIndent
            self.isFirstItemChild = isFirstItemChild
            self.isInsideBlockquote = isInsideBlockquote
        }
    }
    
    // MARK: - Error Handling
    
    private static var lastErrorMessage: String = ""
    
    public static var lastError: String {
        return lastErrorMessage
    }

    // MARK: - Footnote Section Tracking

    private static var hasRenderedFootnoteSection = false
    private static var footnoteDefIndex = 0
    /// Maps cmark-assigned index (1, 2, 3...) → original label ("markdown", "another"...)
    /// Built by scanning markdown before cmark parsing, since cmark-gfm's process_footnotes
    /// overwrites the node literal with the numeric index (blocks.c:496-502).
    private static var footnoteLabelMap: [Int: String] = [:]

    // MARK: - Initialization
    
    private static let initializeOnce: Void = {
        cmark_gfm_core_extensions_ensure_registered()
        MMarkFontLoader.ensureFontsRegistered()
    }()
    
    // MARK: - Public API
    
    /// Convert Markdown to NSAttributedString using node traversal
    public static func markdown(toAttributedString markdown: String,
                               options: Int32,
                               configuration: MMarkStyleConfiguration = .defaultStyle,
                               containerWidth: CGFloat = UIScreen.main.bounds.width - 32) -> NSAttributedString? {
        _ = initializeOnce

        guard !markdown.isEmpty else {
            lastErrorMessage = "Input markdown is empty"
            return NSAttributedString()
        }

        // Preprocess: extract math expressions ($...$, $$...$$) into placeholders
        let preprocessResult = MMarkMathPreprocessor.preprocess(markdown)
        let processedMarkdown = preprocessResult.processedMarkdown

        let utf8Text = processedMarkdown.utf8CString
        let len = utf8Text.count - 1 // Exclude null terminator

        // Create parser
        guard let parser = cmark_parser_new(options) else {
            lastErrorMessage = "Failed to create parser"
            return nil
        }

        defer {
            cmark_parser_free(parser)
        }

        // Attach GFM extensions
        let extensions = ["table", "strikethrough", "tasklist", "autolink", "footnote"]
        for extName in extensions {
            if let ext = cmark_find_syntax_extension(extName) {
                cmark_parser_attach_syntax_extension(parser, ext)
            }
        }

        // Parse document
        utf8Text.withUnsafeBufferPointer { buffer in
            if let baseAddress = buffer.baseAddress {
                cmark_parser_feed(parser, baseAddress, len)
            }
        }

        guard let doc = cmark_parser_finish(parser) else {
            lastErrorMessage = "Failed to parse markdown"
            return nil
        }

        defer {
            cmark_node_free(doc)
        }

        // Build attributed string
        let result = NSMutableAttributedString()
        Self.hasRenderedFootnoteSection = false
        Self.footnoteDefIndex = 0
        // Build index→label mapping for footnotes before cmark parsing
        // (cmark-gfm overwrites the literal with the numeric index)
        Self.buildFootnoteLabelMap(from: processedMarkdown)
        let context = ProcessingContext(configuration: configuration, containerWidth: containerWidth)

        processNode(doc, intoAttributedString: result, context: context)

        // Postprocess: replace math placeholders with styled text or attachments
        postprocessMathPlaceholders(result, preprocessResult: preprocessResult, configuration: configuration, containerWidth: containerWidth)

        lastErrorMessage = ""
        return result
    }
    
    // MARK: - Node Processing
    
    private static func processNode(_ node: UnsafeMutablePointer<cmark_node>?,
                                   intoAttributedString result: NSMutableAttributedString,
                                   context: ProcessingContext) {
        guard let node = node else { return }

        var child = cmark_node_first_child(node)
        while let currentChild = child {
            processSingleNode(currentChild, intoAttributedString: result, context: context)
            child = cmark_node_next(currentChild)
        }
    }

    private static func processSingleNode(_ node: UnsafeMutablePointer<cmark_node>,
                                         intoAttributedString result: NSMutableAttributedString,
                                         context: ProcessingContext) {
        let nodeType = cmark_node_get_type(node)
        
        switch nodeType {
        case CMARK_NODE_DOCUMENT:
            processChildren(node, intoAttributedString: result, context: context)

        case CMARK_NODE_HEADING:
            processHeading(node, intoAttributedString: result, context: context)

        case CMARK_NODE_PARAGRAPH:
            processParagraph(node, intoAttributedString: result, context: context)

        case CMARK_NODE_TEXT:
            processText(node, intoAttributedString: result)

        case CMARK_NODE_CODE:
            processCode(node, intoAttributedString: result, context: context)

        case CMARK_NODE_CODE_BLOCK:
            processCodeBlock(node, intoAttributedString: result, context: context)

        case CMARK_NODE_EMPH:
            processEmph(node, intoAttributedString: result, context: context)

        case CMARK_NODE_STRONG:
            processStrong(node, intoAttributedString: result, context: context)

        case CMARK_NODE_LINK:
            processLink(node, intoAttributedString: result, context: context)

        case CMARK_NODE_IMAGE:
            processImage(node, intoAttributedString: result, context: context)

        case CMARK_NODE_BLOCK_QUOTE:
            processBlockquote(node, intoAttributedString: result, context: context)

        case CMARK_NODE_LIST:
            processList(node, intoAttributedString: result, context: context)

        case CMARK_NODE_ITEM:
            // item is handled within processList
            break

        case CMARK_NODE_THEMATIC_BREAK:
            // Render a horizontal rule via NSTextAttachment
            let horizontalRuleAttachment = MMarkHorizontalRuleAttachment()
            let hrAttrStr = NSMutableAttributedString(attachment: horizontalRuleAttachment)
            // Add spacing before and after
            let finalStr = NSMutableAttributedString(string: "\n")
            finalStr.append(hrAttrStr)
            finalStr.append(NSAttributedString(string: "\n\n"))
            result.append(finalStr)

        case CMARK_NODE_SOFTBREAK, CMARK_NODE_LINEBREAK:
            result.append(NSAttributedString(string: "\n"))

        case CMARK_NODE_FOOTNOTE_REFERENCE:
            processFootnoteReference(node, intoAttributedString: result, context: context)

        case CMARK_NODE_FOOTNOTE_DEFINITION:
            processFootnoteDefinition(node, intoAttributedString: result, context: context)

        default:
            // Handle extension nodes (like tables) by type string
            if let typeStr = cmark_node_get_type_string(node) {
                let type = String(cString: typeStr)
                if type == "table" {
                    processTableNode(node, intoAttributedString: result, context: context)
                    return
                }
                if type == "strikethrough" {
                    processStrikethrough(node, intoAttributedString: result, context: context)
                    return
                }
            }
            processChildren(node, intoAttributedString: result, context: context)
        }
    }

    // MARK: - Specific Node Handlers

    private static func processHeading(_ node: UnsafeMutablePointer<cmark_node>,
                                       intoAttributedString result: NSMutableAttributedString,
                                       context: ProcessingContext) {
        let level = Int(cmark_node_get_heading_level(node))
        let style = context.configuration.headingStyles[level] ?? context.configuration.paragraphStyle

        let paraStyle = NSMutableParagraphStyle()
        paraStyle.paragraphSpacingBefore = context.configuration.headingSpacingBefore[level] ?? 0
        paraStyle.paragraphSpacing = context.configuration.headingSpacing[level] ?? 0
        if context.currentHeadIndent > 0 {
            paraStyle.firstLineHeadIndent = context.currentHeadIndent
            paraStyle.headIndent = context.currentHeadIndent
        }

        var attrs: [NSAttributedString.Key: Any] = [
            .font: style.font,
            .foregroundColor: style.textColor,
            .paragraphStyle: paraStyle
        ]

        if context.isInsideBlockquote {
            attrs[.blockquote] = true
            attrs[.blockquoteDepth] = context.blockquoteDepth
            attrs[.backgroundColor] = context.configuration.blockquoteBackgroundColor
        }

        appendChildren(node, withAttributes: attrs, toAttributedString: result, context: context)
        result.append(NSAttributedString(string: "\n"))
    }

    private static func processParagraph(_ node: UnsafeMutablePointer<cmark_node>,
                                           intoAttributedString result: NSMutableAttributedString,
                                           context: ProcessingContext) {
        let paraStyle = NSMutableParagraphStyle()
        paraStyle.lineSpacing = 4
        // If inside a list or blockquote, use the indentation
        if context.currentHeadIndent > 0 {
            // If it's the first child of a list item, its first line is the bullet line
            paraStyle.firstLineHeadIndent = context.isFirstItemChild ? context.currentIndent : context.currentHeadIndent
            paraStyle.headIndent = context.currentHeadIndent
        }
        
        var attrs: [NSAttributedString.Key: Any] = [
            .font: context.configuration.paragraphStyle.font,
            .foregroundColor: context.isInsideBlockquote ? context.configuration.blockquoteColor : context.configuration.paragraphStyle.textColor,
            .paragraphStyle: paraStyle
        ]
        
        // Add a marker attribute for the renderer to draw the vertical bar
        if context.isInsideBlockquote {
            attrs[.blockquote] = true
            attrs[.blockquoteDepth] = context.blockquoteDepth  // 保存层级信息
            // 添加背景色属性，这样背景会自动跟随滚动
            attrs[.backgroundColor] = context.configuration.blockquoteBackgroundColor
            print("[MMarkParser] Adding blockquote attribute to paragraph, depth: \(context.blockquoteDepth)")
        }
        
        appendChildren(node, withAttributes: attrs, toAttributedString: result, context: context)
        result.append(NSAttributedString(string: "\n\n"))
    }
    private static func processText(_ node: UnsafeMutablePointer<cmark_node>,
                                    intoAttributedString result: NSMutableAttributedString) {
        if let literal = cmark_node_get_literal(node) {
            result.append(NSAttributedString(string: String(cString: literal)))
        }
    }

    private static func processCode(_ node: UnsafeMutablePointer<cmark_node>,
                                    intoAttributedString result: NSMutableAttributedString,
                                    context: ProcessingContext) {
        if let literal = cmark_node_get_literal(node) {
            let style = context.configuration.codeStyle
            let attrs: [NSAttributedString.Key: Any] = [
                .font: style.font,
                .foregroundColor: style.textColor,
                .backgroundColor: style.backgroundColor
            ]
            result.append(NSAttributedString(string: String(cString: literal), attributes: attrs))
        }
    }

    private static func processCodeBlock(_ node: UnsafeMutablePointer<cmark_node>,
                                         intoAttributedString result: NSMutableAttributedString,
                                         context: ProcessingContext) {
        let fence = cmark_node_get_fence_info(node)
        let literal = cmark_node_get_literal(node)
        let rawLanguage = fence != nil ? String(cString: fence!) : ""
        let language = rawLanguage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : rawLanguage.trimmingCharacters(in: .whitespacesAndNewlines)
        let code = literal != nil ? String(cString: literal!) : ""

        let model = MMarkCodeBlockModel.create(language: language, code: code, width: context.containerWidth, configuration: context.configuration)
        let codeAttachment = MMarkCodeBlockAttachment(model: model)
        
        // 创建带缩进的附件字符串
        let attachmentString = NSMutableAttributedString(attachment: codeAttachment)
        
        // 如果在引用或列表中，添加缩进
        if context.currentHeadIndent > 0 {
            let paraStyle = NSMutableParagraphStyle()
            paraStyle.firstLineHeadIndent = context.currentHeadIndent
            paraStyle.headIndent = context.currentHeadIndent
            attachmentString.addAttribute(.paragraphStyle, value: paraStyle, range: NSRange(location: 0, length: attachmentString.length))
        }
        
        // 如果在引用中，添加背景色
        if context.isInsideBlockquote {
            attachmentString.addAttribute(.blockquote, value: true, range: NSRange(location: 0, length: attachmentString.length))
            attachmentString.addAttribute(.blockquoteDepth, value: context.blockquoteDepth, range: NSRange(location: 0, length: attachmentString.length))
            attachmentString.addAttribute(.backgroundColor, value: context.configuration.blockquoteBackgroundColor, range: NSRange(location: 0, length: attachmentString.length))
        }

        result.append(attachmentString)
        result.append(NSAttributedString(string: "\n"))
    }

    private static func processEmph(_ node: UnsafeMutablePointer<cmark_node>,
                                    intoAttributedString result: NSMutableAttributedString,
                                    context: ProcessingContext) {
        let parentFont = currentFont(fromResult: result) ?? context.configuration.paragraphStyle.font
        let italicFont = UIFont.italicSystemFont(ofSize: parentFont.pointSize)
        let textColor = currentColor(fromResult: result) ?? (context.isInsideBlockquote ? context.configuration.blockquoteColor : context.configuration.paragraphStyle.textColor)
        var attrs: [NSAttributedString.Key: Any] = [
            .font: italicFont,
            .foregroundColor: textColor
        ]
        if context.isInsideBlockquote {
            attrs[.blockquote] = true
            attrs[.blockquoteDepth] = context.blockquoteDepth
            attrs[.backgroundColor] = context.configuration.blockquoteBackgroundColor
        }

        // Apply paragraph style for indentation when inside blockquote/list
        if context.currentHeadIndent > 0 {
            let pStyle = NSMutableParagraphStyle()
            pStyle.firstLineHeadIndent = context.currentHeadIndent
            pStyle.headIndent = context.currentHeadIndent
            pStyle.lineSpacing = 4
            attrs[.paragraphStyle] = pStyle
        }

        appendChildren(node, withAttributes: attrs, toAttributedString: result, context: context)
    }

    private static func processStrong(_ node: UnsafeMutablePointer<cmark_node>,
                                      intoAttributedString result: NSMutableAttributedString,
                                      context: ProcessingContext) {
        let parentFont = currentFont(fromResult: result) ?? context.configuration.paragraphStyle.font
        let boldFont = UIFont.boldSystemFont(ofSize: parentFont.pointSize)
        let textColor = currentColor(fromResult: result) ?? (context.isInsideBlockquote ? context.configuration.blockquoteColor : context.configuration.paragraphStyle.textColor)
        var attrs: [NSAttributedString.Key: Any] = [
            .font: boldFont,
            .foregroundColor: textColor
        ]
        if context.isInsideBlockquote {
            attrs[.blockquote] = true
            attrs[.blockquoteDepth] = context.blockquoteDepth
            attrs[.backgroundColor] = context.configuration.blockquoteBackgroundColor
        }

        // Apply paragraph style for indentation when inside blockquote/list
        if context.currentHeadIndent > 0 {
            let pStyle = NSMutableParagraphStyle()
            pStyle.firstLineHeadIndent = context.currentHeadIndent
            pStyle.headIndent = context.currentHeadIndent
            pStyle.lineSpacing = 4
            attrs[.paragraphStyle] = pStyle
        }

        appendChildren(node, withAttributes: attrs, toAttributedString: result, context: context)
    }

    private static func processStrikethrough(_ node: UnsafeMutablePointer<cmark_node>,
                                              intoAttributedString result: NSMutableAttributedString,
                                              context: ProcessingContext) {
        let parentFont = currentFont(fromResult: result) ?? context.configuration.paragraphStyle.font
        let textColor = currentColor(fromResult: result) ?? (context.isInsideBlockquote ? context.configuration.blockquoteColor : context.configuration.paragraphStyle.textColor)
        var attrs: [NSAttributedString.Key: Any] = [
            .font: parentFont,
            .foregroundColor: textColor,
            .strikethroughStyle: NSUnderlineStyle.single.rawValue,
            .strikethroughColor: context.configuration.strikethroughColor
        ]
        if context.isInsideBlockquote {
            attrs[.blockquote] = true
            attrs[.blockquoteDepth] = context.blockquoteDepth
            attrs[.backgroundColor] = context.configuration.blockquoteBackgroundColor
        }

        // Apply paragraph style for indentation when inside blockquote/list
        if context.currentHeadIndent > 0 {
            let pStyle = NSMutableParagraphStyle()
            pStyle.firstLineHeadIndent = context.currentHeadIndent
            pStyle.headIndent = context.currentHeadIndent
            pStyle.lineSpacing = 4
            attrs[.paragraphStyle] = pStyle
        }

        appendChildren(node, withAttributes: attrs, toAttributedString: result, context: context)
    }

    private static func processLink(_ node: UnsafeMutablePointer<cmark_node>,
                                   intoAttributedString result: NSMutableAttributedString,
                                   context: ProcessingContext) {
        let url = cmark_node_get_url(node)
        let font = currentFont(fromResult: result) ?? context.configuration.paragraphStyle.font
        let urlStr = url != nil ? String(cString: url!) : ""
        var attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: context.configuration.linkStyle.textColor,
            .underlineStyle: context.configuration.linkStyle.underlineStyle.rawValue,
            .link: urlStr
        ]
        if context.isInsideBlockquote {
            attrs[.blockquote] = true
            attrs[.blockquoteDepth] = context.blockquoteDepth
            attrs[.backgroundColor] = context.configuration.blockquoteBackgroundColor
        }

        // Apply paragraph style for indentation when inside blockquote/list
        if context.currentHeadIndent > 0 {
            let pStyle = NSMutableParagraphStyle()
            pStyle.firstLineHeadIndent = context.currentHeadIndent
            pStyle.headIndent = context.currentHeadIndent
            pStyle.lineSpacing = 4
            attrs[.paragraphStyle] = pStyle
        }

        appendChildren(node, withAttributes: attrs, toAttributedString: result, context: context)
    }

    private static func processImage(_ node: UnsafeMutablePointer<cmark_node>,
                                     intoAttributedString result: NSMutableAttributedString,
                                     context: ProcessingContext) {
        let url = cmark_node_get_url(node)
        let title = cmark_node_get_title(node)
        let urlStr = url != nil ? String(cString: url!) : ""
        let altText = title != nil ? String(cString: title!) : ""

        let model = MMarkImageModel.create(url: urlStr, alt: altText, width: context.containerWidth)
        let imageAttachment = MMarkImageAttachment(model: model)

        // 创建附件字符串
        let attachmentString = NSMutableAttributedString(attachment: imageAttachment)

        // 如果在引用或列表中，添加缩进
        if context.currentHeadIndent > 0 {
            let paraStyle = NSMutableParagraphStyle()
            paraStyle.firstLineHeadIndent = context.currentHeadIndent
            paraStyle.headIndent = context.currentHeadIndent
            attachmentString.addAttribute(.paragraphStyle, value: paraStyle, range: NSRange(location: 0, length: attachmentString.length))
        }

        // 如果在引用中，添加背景色
        if context.isInsideBlockquote {
            attachmentString.addAttribute(.blockquote, value: true, range: NSRange(location: 0, length: attachmentString.length))
            attachmentString.addAttribute(.blockquoteDepth, value: context.blockquoteDepth, range: NSRange(location: 0, length: attachmentString.length))
            attachmentString.addAttribute(.backgroundColor, value: context.configuration.blockquoteBackgroundColor, range: NSRange(location: 0, length: attachmentString.length))
        }

        result.append(attachmentString)
        result.append(NSAttributedString(string: "\n"))
    }

    // MARK: - Footnote Handlers

    /// Build index→label mapping by scanning markdown for [^label] patterns.
    /// cmark-gfm's process_footnotes assigns sequential indices to unique labels
    /// and overwrites the node literal with the index number (blocks.c:496-502).
    /// This mapping restores the original label from the index.
    private static func buildFootnoteLabelMap(from markdown: String) {
        footnoteLabelMap.removeAll()
        var seenLabels = Set<String>()
        var index = 0

        let pattern = "(?<!\\\\)\\[\\^([^\\]]+)\\]"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return }

        let nsRange = NSRange(markdown.startIndex..<markdown.endIndex, in: markdown)
        let matches = regex.matches(in: markdown, range: nsRange)

        for match in matches {
            guard match.numberOfRanges >= 2 else { continue }
            let labelRange = match.range(at: 1)
            guard let swiftRange = Range(labelRange, in: markdown) else { continue }
            let label = String(markdown[swiftRange])
            if !seenLabels.contains(label) {
                seenLabels.insert(label)
                index += 1
                footnoteLabelMap[index] = label
            }
        }
    }

    private static func processFootnoteReference(_ node: UnsafeMutablePointer<cmark_node>,
                                                  intoAttributedString result: NSMutableAttributedString,
                                                  context: ProcessingContext) {
        guard let literal = cmark_node_get_literal(node) else { return }

        // cmark-gfm process_footnotes overwrites literal with index (e.g., "1")
        let indexStr = String(cString: literal)
        let index = Int(indexStr) ?? 0
        // Look up original label from the index→label mapping
        let originalLabel = Self.footnoteLabelMap[index] ?? indexStr

        let style = context.configuration.footnoteReferenceStyle

        var attrs: [NSAttributedString.Key: Any] = [
            .font: style.font,
            .foregroundColor: style.textColor,
            .link: "footnote://ref/\(originalLabel)",
            .footnoteRef: originalLabel
        ]

        if context.isInsideBlockquote {
            attrs[.blockquote] = true
            attrs[.blockquoteDepth] = context.blockquoteDepth
            attrs[.backgroundColor] = context.configuration.blockquoteBackgroundColor
        }

        result.append(NSAttributedString(string: "[\(originalLabel)]", attributes: attrs))
    }

    private static func processFootnoteDefinition(_ node: UnsafeMutablePointer<cmark_node>,
                                                   intoAttributedString result: NSMutableAttributedString,
                                                   context: ProcessingContext) {
        // Note: cmark_node_get_literal does NOT return the label for FOOTNOTE_DEFINITION
        // (the C API switches on type and definition is not included).
        // Use an incrementing counter for display.
        Self.footnoteDefIndex += 1
        let displayIndex = Self.footnoteDefIndex

        // Add separator + section header before first definition
        if !Self.hasRenderedFootnoteSection {
            Self.hasRenderedFootnoteSection = true
            let hrAttachment = MMarkHorizontalRuleAttachment()
            let hrAttrStr = NSMutableAttributedString(attachment: hrAttachment)
            let headerStr = NSAttributedString(string: "\n Footnotes\n", attributes: [
                .font: context.configuration.headingStyles[2]?.font ?? UIFont.boldSystemFont(ofSize: 20),
                .foregroundColor: context.configuration.paragraphStyle.textColor
            ])
            result.append(NSAttributedString(string: "\n"))
            result.append(hrAttrStr)
            result.append(headerStr)
        }

        // Apply paragraph style for indentation
        let paraStyle = NSMutableParagraphStyle()
        paraStyle.firstLineHeadIndent = context.currentHeadIndent
        paraStyle.headIndent = context.currentHeadIndent

        let backlinkAttrs: [NSAttributedString.Key: Any] = [
            .font: context.configuration.footnoteStyle.font,
            .foregroundColor: context.configuration.footnoteBackrefColor,
            .link: "footnote://backref/\(Self.footnoteLabelMap[displayIndex] ?? String(displayIndex))"
        ]

        let defAttrs: [NSAttributedString.Key: Any] = [
            .font: context.configuration.footnoteStyle.font,
            .foregroundColor: context.configuration.footnoteStyle.textColor,
            .paragraphStyle: paraStyle,
            .footnoteDef: Self.footnoteLabelMap[displayIndex] ?? String(displayIndex)
        ]

        // Render content with indentation

        var childContext = context
        childContext.currentHeadIndent += 20
        childContext.currentIndent += 20
        processChildren(node, intoAttributedString: result, context: childContext)

        // Add backlink ↩
        result.append(NSAttributedString(string: " ↩", attributes: backlinkAttrs))
        result.append(NSAttributedString(string: "\n\n"))
    }

    private static func processBlockquote(_ node: UnsafeMutablePointer<cmark_node>,
                                           intoAttributedString result: NSMutableAttributedString,
                                           context: ProcessingContext) {
        var childContext = context
        childContext.isInsideBlockquote = true
        childContext.blockquoteDepth += 1
        
        // Blockquote indentation - 每层 20pt
        let indent: CGFloat = 20
        childContext.currentIndent += indent
        childContext.currentHeadIndent += indent
        
        // 重要：减少 containerWidth 以适应 blockquote 的缩进
        // 这样附件（代码块、表格）的宽度计算会考虑缩进
        childContext.containerWidth -= indent
        
        print("[MMarkParser] Blockquote depth: \(childContext.blockquoteDepth), indent: \(childContext.currentHeadIndent)")
        
        processChildren(node, intoAttributedString: result, context: childContext)
        result.append(NSAttributedString(string: "\n"))
    }

    private static func processList(_ node: UnsafeMutablePointer<cmark_node>,
                                    intoAttributedString result: NSMutableAttributedString,
                                    context: ProcessingContext) {
        let listType = Int(cmark_node_get_list_type(node).rawValue)
        var childContext = context
        childContext.listDepth += 1
        
        var child = cmark_node_first_child(node)
        while let currentChild = child {
            if cmark_node_get_type(currentChild) == CMARK_NODE_ITEM {
                processItem(currentChild, intoAttributedString: result, context: childContext, listType: listType)
            } else {
                processSingleNode(currentChild, intoAttributedString: result, context: childContext)
            }
            child = cmark_node_next(currentChild)
        }
        result.append(NSAttributedString(string: "\n"))
    }

    private static func processItem(_ node: UnsafeMutablePointer<cmark_node>,
                                    intoAttributedString result: NSMutableAttributedString,
                                    context: ProcessingContext,
                                    listType: Int) {
        // CMARK_BULLET_LIST = 1, CMARK_ORDERED_LIST = 2
        let isOrderedList = listType == 2
        
        // Support up to 6 levels of nesting
        let clampedDepth = min(context.listDepth, 6)
        let bulletMarker = getBulletMarker(for: node, isOrderedList: isOrderedList, depth: clampedDepth)
        
        // Indentation calculation
        let indentPerLevel: CGFloat = 8.0
        let baseIndent: CGFloat = 8.0
        let currentIndent = CGFloat(clampedDepth - 1) * indentPerLevel + baseIndent
        
        // Marker width estimation: ordered lists need more space
        let markerWidth: CGFloat = isOrderedList ? 28.0 : 22.0
        
        var childContext = context
        childContext.currentIndent = context.currentIndent + currentIndent
        childContext.currentHeadIndent = context.currentHeadIndent + currentIndent + markerWidth

        // 调整 containerWidth 以适应列表项的缩进（基于父级上下文，叠加列表缩进）
        childContext.containerWidth = context.containerWidth - (currentIndent + markerWidth)

        var child = cmark_node_first_child(node)
        var isFirstChild = true
        
        while let currentChild = child {
            var itemChildContext = childContext
            itemChildContext.isFirstItemChild = isFirstChild
            
            if isFirstChild {
                let paraStyle = NSMutableParagraphStyle()
                paraStyle.firstLineHeadIndent = itemChildContext.currentIndent
                paraStyle.headIndent = itemChildContext.currentHeadIndent
                paraStyle.lineSpacing = 4

                let textColor = context.isInsideBlockquote ? context.configuration.blockquoteColor : context.configuration.paragraphStyle.textColor
                var attrs: [NSAttributedString.Key: Any] = [
                    .font: context.configuration.paragraphStyle.font,
                    .foregroundColor: textColor,
                    .paragraphStyle: paraStyle
                ]

                if context.isInsideBlockquote {
                    attrs[.blockquote] = true
                    attrs[.blockquoteDepth] = context.blockquoteDepth
                    attrs[.backgroundColor] = context.configuration.blockquoteBackgroundColor
                }
                
                result.append(NSAttributedString(string: bulletMarker + " ", attributes: attrs))
            }
            
            processSingleNode(currentChild, intoAttributedString: result, context: itemChildContext)
            isFirstChild = false
            child = cmark_node_next(currentChild)
        }
    }
    
    private static func getBulletMarker(for node: UnsafeMutablePointer<cmark_node>, isOrderedList: Bool, depth: Int) -> String {
        if isOrderedList {
            guard let listNode = cmark_node_parent(node) else { return "1." }
            let start = Int(cmark_node_get_list_start(listNode))
            let delimiter = cmark_node_get_list_delim(listNode)
            
            // Calculate index of this item in the list
            var index = 1
            var prev = cmark_node_previous(node)
            while let p = prev {
                if cmark_node_get_type(p) == CMARK_NODE_ITEM {
                    index += 1
                }
                prev = cmark_node_previous(p)
            }
            
            let currentNumber = start + index - 1
            let delimiterChar = (delimiter.rawValue == 2) ? ")" : "." // CMARK_PAREN_DELIM = 2
            return "\(currentNumber)\(delimiterChar)"
        } else {
            // Task list check:
            // 1. Check using the GFM extension helper (most reliable for checked state)
            if cmark_gfm_extensions_get_tasklist_item_checked(node) {
                return "▪"
            }
            
            // 2. Check if it's a task item but unchecked.
            if let typeStrPtr = cmark_node_get_type_string(node) {
                let typeStr = String(cString: typeStrPtr)
                if typeStr == "tasklist" {
                    return "▫" // Since get_checked returned false
                }
            }
            
            if cmark_node_get_syntax_extension(node) != nil {
                // If it has an extension in a bullet list, it's likely a tasklist
                return "▫" // Since get_checked returned false
            }
            
            // Unordered list bullets: Level 1 uses •, subsequent levels use ◦
            return depth == 1 ? "•" : "◦"
        }
    }

    private static func processTableNode(_ node: UnsafeMutablePointer<cmark_node>,
                                        intoAttributedString result: NSMutableAttributedString,
                                        context: ProcessingContext) {
        let tableConfig = MMarkTableView.MMarkTableConfig()
        var headerCells: [NSAttributedString] = []
        var dataRows: [[NSAttributedString]] = []

        // Extract column alignments from the table node
        var alignments: [NSTextAlignment] = []
        if let alignPtr = cmark_gfm_extensions_get_table_alignments(node) {
            let nCols = cmark_gfm_extensions_get_table_columns(node)
            for i in 0..<nCols {
                let align = alignPtr[Int(i)]
                switch align {
                case 99: // 'c' = center
                    alignments.append(.center)
                case 114: // 'r' = right
                    alignments.append(.right)
                default: // 0 or 'l' = left
                    alignments.append(.left)
                }
            }
        }

        var child = cmark_node_first_child(node)
        while let currentChild = child {
            if let typeStr = cmark_node_get_type_string(currentChild) {
                let childType = String(cString: typeStr)
                if childType == "table_header" || childType == "table_row" {
                    var rowCells: [NSAttributedString] = []
                    var cell = cmark_node_first_child(currentChild)
                    while let currentCell = cell {
                        let isHeader = childType == "table_header"
                        let baseFont = isHeader ? tableConfig.headerFont : tableConfig.cellFont
                        let attrText = extractAttributedText(from: currentCell, context: context, baseFont: baseFont, baseColor: tableConfig.textColor)
                        rowCells.append(attrText)
                        cell = cmark_node_next(currentCell)
                    }

                    if childType == "table_header" {
                        headerCells = rowCells
                    } else {
                        dataRows.append(rowCells)
                    }
                }
            }
            child = cmark_node_next(currentChild)
        }

        let model = MMarkTableModel.create(headerCells: headerCells, dataRows: dataRows, alignments: alignments, width: context.containerWidth, configuration: context.configuration)
        let tableAttachment = MMarkTableAttachment(model: model)

        // 创建带缩进的附件字符串
        let attachmentString = NSMutableAttributedString(attachment: tableAttachment)

        // 如果在引用或列表中，添加缩进
        if context.currentHeadIndent > 0 {
            let paraStyle = NSMutableParagraphStyle()
            paraStyle.firstLineHeadIndent = context.currentHeadIndent
            paraStyle.headIndent = context.currentHeadIndent
            attachmentString.addAttribute(.paragraphStyle, value: paraStyle, range: NSRange(location: 0, length: attachmentString.length))
        }

        // 如果在引用中，添加背景色
        if context.isInsideBlockquote {
            attachmentString.addAttribute(.blockquote, value: true, range: NSRange(location: 0, length: attachmentString.length))
            attachmentString.addAttribute(.blockquoteDepth, value: context.blockquoteDepth, range: NSRange(location: 0, length: attachmentString.length))
            attachmentString.addAttribute(.backgroundColor, value: context.configuration.blockquoteBackgroundColor, range: NSRange(location: 0, length: attachmentString.length))
        }

        result.append(attachmentString)
        result.append(NSAttributedString(string: "\n"))
    }

    private static func extractAttributedText(from node: UnsafeMutablePointer<cmark_node>,
                                              context: ProcessingContext,
                                              baseFont: UIFont,
                                              baseColor: UIColor) -> NSAttributedString {
        // Leaf nodes: text and code have literals
        if let literal = cmark_node_get_literal(node) {
            let type = cmark_node_get_type(node)
            if type == CMARK_NODE_CODE {
                let codeStyle = context.configuration.codeStyle
                return NSAttributedString(string: String(cString: literal), attributes: [
                    .font: codeStyle.font,
                    .foregroundColor: codeStyle.textColor,
                    .backgroundColor: codeStyle.backgroundColor
                ])
            } else if type == CMARK_NODE_HTML_INLINE {
                let html = String(cString: literal).lowercased().trimmingCharacters(in: .whitespaces)
                if html == "<br>" || html == "<br/>" || html == "<br />" {
                    return NSAttributedString(string: "\n", attributes: [.font: baseFont, .foregroundColor: baseColor])
                }
                return NSAttributedString(string: String(cString: literal), attributes: [
                    .font: baseFont,
                    .foregroundColor: baseColor
                ])
            } else {
                return NSAttributedString(string: String(cString: literal), attributes: [
                    .font: baseFont,
                    .foregroundColor: baseColor
                ])
            }
        }

        let result = NSMutableAttributedString()
        var child = cmark_node_first_child(node)
        while let childNode = child {
            let type = cmark_node_get_type(childNode)
            switch type {
            case CMARK_NODE_TEXT:
                if let literal = cmark_node_get_literal(childNode) {
                    result.append(NSAttributedString(string: String(cString: literal), attributes: [.font: baseFont, .foregroundColor: baseColor]))
                }
            case CMARK_NODE_CODE:
                if let literal = cmark_node_get_literal(childNode) {
                    let codeStyle = context.configuration.codeStyle
                    result.append(NSAttributedString(string: String(cString: literal), attributes: [
                        .font: codeStyle.font,
                        .foregroundColor: codeStyle.textColor,
                        .backgroundColor: codeStyle.backgroundColor
                    ]))
                }
            case CMARK_NODE_HTML_INLINE:
                if let literal = cmark_node_get_literal(childNode) {
                    let html = String(cString: literal).lowercased().trimmingCharacters(in: .whitespaces)
                    // Treat <br>, <br/>, <br /> as line breaks
                    if html == "<br>" || html == "<br/>" || html == "<br />" {
                        result.append(NSAttributedString(string: "\n", attributes: [.font: baseFont, .foregroundColor: baseColor]))
                    } else {
                        result.append(NSAttributedString(string: String(cString: literal), attributes: [.font: baseFont, .foregroundColor: baseColor]))
                    }
                }
            case CMARK_NODE_EMPH:
                let italicFont = UIFont.italicSystemFont(ofSize: baseFont.pointSize)
                result.append(extractAttributedText(from: childNode, context: context, baseFont: italicFont, baseColor: baseColor))
            case CMARK_NODE_STRONG:
                let boldFont = UIFont.boldSystemFont(ofSize: baseFont.pointSize)
                result.append(extractAttributedText(from: childNode, context: context, baseFont: boldFont, baseColor: baseColor))
            case CMARK_NODE_LINK:
                if let url = cmark_node_get_url(childNode) {
                    let urlStr = String(cString: url)
                    let linkText = extractAttributedText(from: childNode, context: context, baseFont: baseFont, baseColor: baseColor)
                    let linkStr = NSMutableAttributedString(attributedString: linkText)
                    linkStr.addAttributes([
                        .foregroundColor: context.configuration.linkStyle.textColor,
                        .underlineStyle: context.configuration.linkStyle.underlineStyle.rawValue,
                        .link: urlStr
                    ], range: NSRange(location: 0, length: linkStr.length))
                    result.append(linkStr)
                }
            case CMARK_NODE_SOFTBREAK, CMARK_NODE_LINEBREAK:
                result.append(NSAttributedString(string: "\n", attributes: [.font: baseFont, .foregroundColor: baseColor]))
            case CMARK_NODE_LIST:
                let listType = Int(cmark_node_get_list_type(childNode).rawValue)
                let isOrdered = listType == 2
                var itemIndex = 1
                var itemChild = cmark_node_first_child(childNode)
                while let item = itemChild {
                    if cmark_node_get_type(item) == CMARK_NODE_ITEM {
                        let marker = isOrdered ? "\(itemIndex)." : "•"
                        result.append(NSAttributedString(string: "\n\(marker) ", attributes: [.font: baseFont, .foregroundColor: baseColor]))
                        let itemText = extractAttributedText(from: item, context: context, baseFont: baseFont, baseColor: baseColor)
                        result.append(itemText)
                        itemIndex += 1
                    }
                    itemChild = cmark_node_next(item)
                }
            default:
                // Check for extension node types like strikethrough
                if let typeStr = cmark_node_get_type_string(childNode) {
                    let nodeTypeStr = String(cString: typeStr)
                    if nodeTypeStr == "strikethrough" {
                        let childText = extractAttributedText(from: childNode, context: context, baseFont: baseFont, baseColor: baseColor)
                        let strikeStr = NSMutableAttributedString(attributedString: childText)
                        strikeStr.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: NSRange(location: 0, length: strikeStr.length))
                        strikeStr.addAttribute(.strikethroughColor, value: context.configuration.strikethroughColor, range: NSRange(location: 0, length: strikeStr.length))
                        result.append(strikeStr)
                        break
                    }
                }
                result.append(extractAttributedText(from: childNode, context: context, baseFont: baseFont, baseColor: baseColor))
            }
            child = cmark_node_next(childNode)
        }
        return result
    }
    
    private static func processChildren(_ node: UnsafeMutablePointer<cmark_node>,
                                       intoAttributedString result: NSMutableAttributedString,
                                       context: ProcessingContext) {
        var child = cmark_node_first_child(node)
        while let currentChild = child {
            processSingleNode(currentChild, intoAttributedString: result, context: context)
            child = cmark_node_next(currentChild)
        }
    }
    
    private static func appendChildren(_ node: UnsafeMutablePointer<cmark_node>,
                                      withAttributes attrs: [NSAttributedString.Key: Any],
                                      toAttributedString result: NSMutableAttributedString,
                                      context: ProcessingContext) {
        var child = cmark_node_first_child(node)
        while let currentChild = child {
            let type = cmark_node_get_type(currentChild)
            if type == CMARK_NODE_TEXT {
                if let literal = cmark_node_get_literal(currentChild) {
                    result.append(NSAttributedString(string: String(cString: literal), attributes: attrs))
                }
            } else if type == CMARK_NODE_CODE {
                if let literal = cmark_node_get_literal(currentChild) {
                    var codeAttrs = attrs
                    codeAttrs[.font] = context.configuration.codeStyle.font
                    codeAttrs[.foregroundColor] = context.configuration.codeStyle.textColor
                    codeAttrs[.backgroundColor] = context.configuration.codeStyle.backgroundColor
                    result.append(NSAttributedString(string: String(cString: literal), attributes: codeAttrs))
                }
            } else {
                processSingleNode(currentChild, intoAttributedString: result, context: context)
            }
            child = cmark_node_next(currentChild)
        }
    }
    
    private static func currentFont(fromResult result: NSAttributedString) -> UIFont? {
        guard result.length > 0 else { return nil }
        return result.attribute(.font, at: result.length - 1, effectiveRange: nil) as? UIFont
    }
    
    private static func currentColor(fromResult result: NSAttributedString) -> UIColor? {
        guard result.length > 0 else { return nil }
        return result.attribute(.foregroundColor, at: result.length - 1, effectiveRange: nil) as? UIColor
    }

    // MARK: - Chemistry to LaTeX Conversion

    /// Convert chemistry notation (\ce{...}, \chemfig{...}) to LaTeX math
    /// that MTMathUILabel can render, using the mhchem-to-LaTeX mapping table.
    private static func convertChemistryToLatex(_ latex: String) -> String {
        var result = latex

        // Handle \chemfig{...} first: structural diagrams can't be converted to math,
        // replace with \text{[...]} to show as plain text in math mode
        do {
            let pattern = "\\\\chemfig\\{([^}]*)\\}"
            let regex = try NSRegularExpression(pattern: pattern)
            let matches = regex.matches(in: result, range: NSRange(location: 0, length: result.utf16.count))

            for match in matches.reversed() {
                let fullRange = match.range(at: 0)
                let contentRange = match.range(at: 1)
                let content = (result as NSString).substring(with: contentRange)
                let replacement = "\\text{[\(content)]}"
                result = (result as NSString).replacingCharacters(in: fullRange, with: replacement)
            }
        } catch {
            print("[MMarkParser] convertChemistryToLatex regex error: \(error)")
        }

        // Handle \ce{...} commands with full conversion
        do {
            let pattern = "\\\\ce\\{([^}]*)\\}"
            let regex = try NSRegularExpression(pattern: pattern)
            let matches = regex.matches(in: result, range: NSRange(location: 0, length: result.utf16.count))

            for match in matches.reversed() {
                let fullRange = match.range(at: 0)
                let contentRange = match.range(at: 1)
                let content = (result as NSString).substring(with: contentRange)
                let converted = convertCeContent(content)
                result = (result as NSString).replacingCharacters(in: fullRange, with: converted)
            }
        } catch {
            print("[MMarkParser] convertChemistryToLatex regex error: \(error)")
        }

        return result
    }

    /// Convert mhchem \ce{...} content to LaTeX math.
    /// Handles: subscripts, superscripts/charges, arrows, coefficients, \mathrm wrapping.
    private static func convertCeContent(_ content: String) -> String {
        // Step 1: Protect existing LaTeX commands (\command, \command[...]{...}) with placeholders.
        var protected: [String: String] = [:]
        var counter = 0
        var result = protectLatexCommands(content, protected: &protected, counter: &counter)

        // Step 2: Handle reaction arrows (order matters: most specific first).
        // Double-condition: ->[A][B] → \xrightarrow[B]{A} (mhchem top/bottom reversed)
        result = applyArrowRule(result, pattern: "->\\[([^\\]]*)\\]\\[([^\\]]*)\\]") { groups in
            let above = groups[1]; let below = groups[2]
            return "\\xrightarrow[\\text{\(below)}]{\\text{\(above)}}"
        }
        // Single-condition: ->[A] → \xrightarrow{\text{A}}
        result = applyArrowRule(result, pattern: "->\\[([^\\]]*)\\]") { groups in
            return "\\xrightarrow{\\text{\(groups[1])}}"
        }
        // Plain arrow
        result = result.replacingOccurrences(of: "->", with: "\\rightarrow")
        // Equilibrium arrow
        result = result.replacingOccurrences(of: "<=>", with: "\\rightleftharpoons")

        // Step 3: Split by " + " operator and process each formula segment.
        let segments = result.components(separatedBy: " + ")
        let processed = segments.map { segment -> String in
            if segment.isEmpty { return segment }
            return processCeSegment(segment, protected: protected)
        }
        result = processed.joined(separator: " + ")

        // Step 4: Restore protected commands.
        for (key, value) in protected {
            result = result.replacingOccurrences(of: key, with: value)
        }

        return result
    }

    /// Protect LaTeX commands (\command, \command[...]{...}) with unique placeholders.
    /// Returns the string with commands replaced, and fills the protected dictionary.
    private static func protectLatexCommands(_ text: String, protected: inout [String: String], counter: inout Int) -> String {
        var result = text
        let pattern = "\\\\[a-zA-Z]+(?:\\[[^\\]]*\\])?(?:\\{[^\\}]*\\})?"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return result }

        let matches = regex.matches(in: result, range: NSRange(location: 0, length: result.utf16.count))
        for match in matches.reversed() {
            let fullRange = match.range(at: 0)
            let cmd = (result as NSString).substring(with: fullRange)
            let key = "\u{0000}CE\(counter)\u{0000}"
            counter += 1
            protected[key] = cmd
            result = (result as NSString).replacingCharacters(in: fullRange, with: key)
        }
        return result
    }

    /// Apply a regex-based arrow replacement with a closure that receives capture groups.
    private static func applyArrowRule(_ text: String, pattern: String, transform: ([String]) -> String) -> String {
        var result = text
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return result }
        let matches = regex.matches(in: result, range: NSRange(location: 0, length: result.utf16.count))

        for match in matches.reversed() {
            let fullRange = match.range(at: 0)
            var groups: [String] = []
            for i in 0..<match.numberOfRanges {
                let r = match.range(at: i)
                groups.append(r.location != NSNotFound ? (result as NSString).substring(with: r) : "")
            }
            let replacement = transform(groups)
            result = (result as NSString).replacingCharacters(in: fullRange, with: replacement)
        }
        return result
    }

    /// Process a single formula segment (e.g., "2H2O", "Cu^2+", "[Ag(NH3)2]+").
    /// Handles protected placeholders within the segment.
    private static func processCeSegment(_ segment: String, protected: [String: String]) -> String {
        // Split segment into formula parts and protected placeholders

        var parts: [(isProtected: Bool, text: String)] = []
        var currentFormula = ""
        var inProtected = false
        var protectedBuffer = ""

        for char in segment {
            if char == "\u{0000}" {
                if !currentFormula.isEmpty {
                    parts.append((false, currentFormula))
                    currentFormula = ""
                }
                inProtected.toggle()
                if inProtected {
                    protectedBuffer = String(char)
                } else {
                    protectedBuffer.append(char)
                    parts.append((true, protectedBuffer))
                    protectedBuffer = ""
                }
                continue
            }

            if inProtected {
                protectedBuffer.append(char)
            } else {
                if char.isLetter || char.isNumber || "()[]^+_-".contains(char) {
                    currentFormula.append(char)
                } else {
                    if !currentFormula.isEmpty {
                        parts.append((false, currentFormula))
                        currentFormula = ""
                    }
                    parts.append((true, String(char)))
                }
            }
        }
        if !currentFormula.isEmpty {
            parts.append((false, currentFormula))
        }
        if inProtected && !protectedBuffer.isEmpty {
            parts.append((true, protectedBuffer))
        }

        // Process each part
        let processed = parts.map { part -> String in
            if part.isProtected {
                // Check if this is a known placeholder or just formula characters
                if protected.keys.contains(part.text) {
                    return part.text // Will be restored later
                }
                // It's formula chars not caught by the loop above (e.g., "_")
                return convertFormulaToLatex(part.text)
            } else {
                return convertFormulaToLatex(part.text)
            }
        }

        return processed.joined()
    }

    /// Convert a chemical formula string to LaTeX math.
    /// Handles: subscripts, charges/superscripts, \mathrm wrapping.
    private static func convertFormulaToLatex(_ formula: String) -> String {
        // Preserve known LaTeX commands (already protected, but safe check)
        if formula.hasPrefix("\\") { return formula }
        // If it's just an operator or whitespace, return as-is
        if formula.allSatisfy({ $0.isWhitespace || $0 == "+" || $0 == "=" }) { return formula }

        var s = formula

        // Extract leading coefficient (digits at start)
        var coefficient = ""
        while let first = s.first, first.isNumber {
            coefficient.append(first)
            s.removeFirst()
        }
        if coefficient.isEmpty && s.isEmpty { return formula }

        // Early exit: if remaining is only digits, return as-is
        if s.allSatisfy({ $0.isPunctuation || $0 == "+" || $0 == "-" }) {
            return coefficient + s
        }

        // Extract superscript charge
        var charge = ""
        if let hatIdx = s.firstIndex(of: "^") {
            let afterHat = s[s.index(after: hatIdx)...]
            if afterHat.hasPrefix("{") {
                // ^{...} pattern, find matching }
                let fromIdx = s.index(after: hatIdx)
                let afterOpen = s.index(after: fromIdx)
                if let closeIdx = s[afterOpen...].firstIndex(of: "}") {
                    charge = String(s[hatIdx...closeIdx])
                    s = String(s[..<hatIdx])
                }
            } else {
                // ^2+, ^+, ^3- etc.
                var chargeContent = ""
                for c in afterHat {
                    if c == "+" || c == "-" || c.isNumber { chargeContent.append(c) }
                    else { break }
                }
                if !chargeContent.isEmpty {
                    charge = "^{\(chargeContent)}"
                    s = String(s[..<hatIdx])
                }
            }
        }

        // Check for trailing + or - as charge (only if no ^-based charge was found)
        if charge.isEmpty, let last = s.last, last == "+" || last == "-" {
            // Heuristic: if preceded by letter, ), ], or it's the 2nd+ char...
            if s.count >= 2 {
                let lastIdx = s.index(before: s.endIndex)
                let penultimateIdx = s.index(before: lastIdx)
                let penultimate = s[penultimateIdx]
                if penultimate.isLetter || penultimate == ")" || penultimate == "]" {
                    let chargeContent = String(last)
                    s = String(s.dropLast())
                    charge = "^{\(chargeContent)}"
                }
            }
        }

        // Convert subscripts: letter/paren/bracket followed by digits → letter_{digits}
        do {
            let subPattern = try NSRegularExpression(pattern: "([A-Za-z\\)\\]])(\\d+)")
            let subMatches = subPattern.matches(in: s, range: NSRange(location: 0, length: s.utf16.count))
            for match in subMatches.reversed() {
                let fullRange = match.range(at: 0)
                let letter = (s as NSString).substring(with: match.range(at: 1))
                let digits = (s as NSString).substring(with: match.range(at: 2))
                let replacement = "\(letter)_{\(digits)}"
                s = (s as NSString).replacingCharacters(in: fullRange, with: replacement)
            }
        } catch {}

        // Wrap in \mathrm{}
        if !s.isEmpty {
            let body = "\\mathrm{\(s)}"
            return coefficient + body + charge
        } else if !charge.isEmpty {
            return coefficient + charge
        }

        return coefficient + s + charge
    }

    // MARK: - Math Post-Processing

    /// Replace math placeholders in the attributed string with styled text or attachments.
    private static func postprocessMathPlaceholders(_ result: NSMutableAttributedString,
                                                     preprocessResult: MMarkMathPreprocessor.Result,
                                                     configuration: MMarkStyleConfiguration,
                                                     containerWidth: CGFloat) {
        // Process block math placeholders first
        for (placeholder, latex) in preprocessResult.blockMathPlaceholders {
            let convertedLatex = convertChemistryToLatex(latex)
            replacePlaceholderInString(result, placeholder: placeholder) { range in
                print("[MMarkParser] Replacing block math placeholder: \(placeholder) -> \(convertedLatex.prefix(40))")
                let model = MMarkMathBlockModel.create(latex: convertedLatex, width: containerWidth, configuration: configuration)
                let attachment = MMarkMathBlockAttachment(model: model)
                let attrStr = NSMutableAttributedString(attachment: attachment)
                // Preserve paragraph style from original range for proper layout
                if let paraStyle = result.attribute(.paragraphStyle, at: range.location, effectiveRange: nil) as? NSParagraphStyle {
                    attrStr.addAttribute(.paragraphStyle, value: paraStyle, range: NSRange(location: 0, length: attrStr.length))
                }
                // Preserve blockquote attributes so the quote bar renders continuously
                if result.attribute(.blockquote, at: range.location, effectiveRange: nil) != nil {
                    let depth = result.attribute(.blockquoteDepth, at: range.location, effectiveRange: nil) as? Int ?? 1
                    let bgColor = result.attribute(.backgroundColor, at: range.location, effectiveRange: nil) as? UIColor
                    attrStr.addAttribute(.blockquote, value: true, range: NSRange(location: 0, length: attrStr.length))
                    attrStr.addAttribute(.blockquoteDepth, value: depth, range: NSRange(location: 0, length: attrStr.length))
                    if let bg = bgColor {
                        attrStr.addAttribute(.backgroundColor, value: bg, range: NSRange(location: 0, length: attrStr.length))
                    }
                }
                return attrStr
            }
        }

        // Process inline math placeholders
        for (placeholder, latex) in preprocessResult.inlineMathPlaceholders {
            let convertedLatex = convertChemistryToLatex(latex)
            replacePlaceholderInString(result, placeholder: placeholder) { _ in
                print("[MMarkParser] Replacing inline math placeholder: \(placeholder) -> \(convertedLatex.prefix(40))")
                return renderInlineMathImage(latex: convertedLatex, configuration: configuration)
            }
        }
    }

    /// Render inline LaTeX as an NSTextAttachment image using MTMathUILabel.
    private static func renderInlineMathImage(latex: String, configuration: MMarkStyleConfiguration) -> NSAttributedString {
        let label = MTMathUILabel()
        label.latex = latex
        label.mode = .text
        if let mathFont = configuration.mathDisplayFont {
            label.font = mathFont
        } else {
            label.fontSize = configuration.mathInlineStyle.font.pointSize
        }
        label.textColor = configuration.mathInlineStyle.textColor
        label.contentInsets = .zero
        label.sizeToFit()

        let labelSize = label.frame.size
        guard labelSize.width > 0 && labelSize.height > 0 else {
            // Fallback: return plain text if rendering fails
            let style = configuration.mathInlineStyle
            return NSAttributedString(string: latex, attributes: [
                .font: style.font,
                .foregroundColor: style.textColor,
                .backgroundColor: style.backgroundColor
            ])
        }

        // Render the label to an image
        let renderer = UIGraphicsImageRenderer(size: labelSize)
        let image = renderer.image { ctx in
            // Clear background (transparent)
            UIColor.clear.setFill()
            ctx.fill(CGRect(origin: .zero, size: labelSize))

            // Flip the context vertically: UIGraphicsImageRenderer uses top-left origin,
            // but CALayer.render(in:) expects bottom-left origin.
            ctx.cgContext.translateBy(x: 0, y: labelSize.height)
            ctx.cgContext.scaleBy(x: 1, y: -1)

            // Render the label
            label.layer.render(in: ctx.cgContext)
        }

        // Create text attachment with the rendered image
        let attachment = NSTextAttachment()
        attachment.image = image
        // Adjust bounds so the image aligns with text baseline
        let font = configuration.paragraphStyle.font
        let capHeight = font.capHeight
        let imageHeight = labelSize.height
        let descent = (imageHeight - capHeight) / 2
        attachment.bounds = CGRect(x: 0, y: -descent, width: labelSize.width, height: imageHeight)

        return NSAttributedString(attachment: attachment)
    }

    /// Find all occurrences of a placeholder string in the attributed string and replace each.
    /// Processes in reverse order to maintain range validity during replacement.
    private static func replacePlaceholderInString(_ result: NSMutableAttributedString,
                                                    placeholder: String,
                                                    replacement: (NSRange) -> NSAttributedString) {
        let fullText = result.string as NSString
        var searchRange = NSRange(location: 0, length: fullText.length)
        var ranges: [NSRange] = []

        while searchRange.location < fullText.length {
            let foundRange = fullText.range(of: placeholder, options: [], range: searchRange)
            if foundRange.location == NSNotFound { break }
            ranges.append(foundRange)
            let nextLocation = foundRange.location + foundRange.length
            searchRange = NSRange(location: nextLocation, length: fullText.length - nextLocation)
        }

        if ranges.isEmpty {
            print("[MMarkParser] WARNING: Placeholder not found in text: \(placeholder)")
            // Debug: print surrounding text to help diagnose
            let searchRange = fullText.range(of: "MMATH")
            if searchRange.location != NSNotFound {
                let context = fullText.substring(with: NSRange(location: max(0, searchRange.location - 10), length: min(fullText.length - searchRange.location + 10, 60)))
                print("[MMarkParser] Found 'MMATH' in text at: \(context)")
            }
        }

        // Replace in reverse order to preserve range validity
        for range in ranges.reversed() {
            let replacementString = replacement(range)
            result.replaceCharacters(in: range, with: replacementString)
        }
    }
}
