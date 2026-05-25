import Foundation
@preconcurrency import iosMath
import UIKit
import md4c
import ObjectiveC

extension NSAttributedString.Key {
    public static let blockquote = NSAttributedString.Key("MMarkBlockquote")
    public static let blockquoteDepth = NSAttributedString.Key("MMarkBlockquoteDepth")
    public static let footnoteRef = NSAttributedString.Key("MMarkFootnoteRef")
    public static let footnoteDef = NSAttributedString.Key("MMarkFootnoteDef")
}

// MARK: - md4c Callback Handler

/// Processes md4c SAX callbacks and builds an NSAttributedString incrementally.
@available(iOS 15.0, *)
private final class _MD4CHandler {

    // MARK: Output & Configuration

    var result = NSMutableAttributedString()
    let configuration: MMarkStyleConfiguration
    var containerWidth: CGFloat

    // MARK: Context State

    var blockquoteDepth = 0
    var isInsideBlockquote = false
    var listDepth = 0
    var currentIndent: CGFloat = 0
    var currentHeadIndent: CGFloat = 0
    var isFirstItemChild = false
    var isInsideFootnoteDef = false
    var currentFootnoteDefLabel = ""
    /// Stack: true = ordered, false = unordered
    var listTypeStack: [Bool] = []
    /// Ordered list item counters (one per nested OL)
    var orderedListItemCounters: [Int] = []

    // MARK: Attribute Stack

    private var attrStack: [[NSAttributedString.Key: Any]] = []
    var currentAttrs: [NSAttributedString.Key: Any] = [:]

    private func pushAttrs() {
        attrStack.append(currentAttrs)
    }

    private func popAttrs() {
        guard !attrStack.isEmpty else {
            print("[MMarkParser] WARNING: attrStack underflow — unbalanced enter/leave callbacks")
            return
        }
        currentAttrs = attrStack.removeLast()
    }

    // MARK: Code Block Accumulation

    var codeBlockLang = ""
    var codeBlockContent = ""
    var isInCodeBlock = false

    // MARK: Table Accumulation

    var tableAccum: _MDTableAccumulator?

    // MARK: List Item State Stack (saved for restore on leave)

    var _liStateStack: [(itemIndent: CGFloat, markerWidth: CGFloat, containerWidthDelta: CGFloat)] = []

    /// Track tight vs loose list mode for current nesting level.
    /// md4c tight-list items have NO paragraph wrapping — we must add \n between them ourselves.
    var _tightListStack: [Bool] = []

    // MARK: Math State

    var isDisplayMath = false

    // MARK: Image Span State

    var isInImageSpan = false
    var _imgAltBuffer = ""
    var _imgUrlBuffer = ""

    // MARK: Footnote Accumulation
    
    var footnoteBuffer = NSMutableAttributedString()
    var isCollectingFootnotes = false

    // MARK: Init

    init(configuration: MMarkStyleConfiguration, containerWidth: CGFloat) {
        self.configuration = configuration
        self.containerWidth = containerWidth
    }

    // MARK: Output Helpers

    /// Append attributed string to the current output context.
    /// Redirects to cell buffer if inside a table cell, footnote buffer if collecting footnotes, otherwise appends to result.
    private func output(_ attrString: NSAttributedString) {
        if let cb = cellBuffer { cb.append(attrString) }
        else if isCollectingFootnotes { footnoteBuffer.append(attrString) }
        else { result.append(attrString) }
    }

    /// Append plain string with optional attributes to the current output context.
    private func output(_ string: String, attributes: [NSAttributedString.Key: Any]? = nil) {
        let attrStr: NSAttributedString
        if let attrs = attributes {
            attrStr = NSAttributedString(string: string, attributes: attrs)
        } else {
            attrStr = NSAttributedString(string: string)
        }
        output(attrStr)
    }

    // MARK: - Block Handlers

    func enterBlock(_ type: MD_BLOCKTYPE, detail: UnsafeMutableRawPointer?) {
        switch type {
        case MD_BLOCK_DOC:
            pushAttrs()

        case MD_BLOCK_QUOTE:
            pushAttrs()
            isInsideBlockquote = true
            blockquoteDepth += 1
            // 引用块缩进 = 引用条宽度 + 间距
            // 确保引用条和文本之间有足够的空间
            let borderWidth = configuration.blockquoteBorderWidth
            let spacing: CGFloat = 8.0 // 引用条和文本之间的间距
            let indent: CGFloat = borderWidth + spacing
            currentIndent += indent
            currentHeadIndent += indent
            containerWidth -= indent

        case MD_BLOCK_UL:
            // Nested list inside a tight parent → need \n between text and nested list
            if _tightListStack.last == true && !listTypeStack.isEmpty {
                let currentStr = cellBuffer?.string ?? result.string
                if !currentStr.hasSuffix("\n") {
                    output("\n")
                }
            }
            pushAttrs()
            listDepth += 1
            listTypeStack.append(false)
            if let d = detail?.assumingMemoryBound(to: MD_BLOCK_UL_DETAIL.self) {
                _tightListStack.append(d.pointee.is_tight != 0)
            } else { _tightListStack.append(true) }

        case MD_BLOCK_OL:
            // Nested list inside a tight parent → need \n between text and nested list
            if _tightListStack.last == true && !listTypeStack.isEmpty {
                let currentStr = cellBuffer?.string ?? result.string
                if !currentStr.hasSuffix("\n") {
                    output("\n")
                }
            }
            pushAttrs()
            listDepth += 1
            listTypeStack.append(true)
            orderedListItemCounters.append(0)
            if let d = detail?.assumingMemoryBound(to: MD_BLOCK_OL_DETAIL.self) {
                _tightListStack.append(d.pointee.is_tight != 0)
            } else { _tightListStack.append(true) }

        case MD_BLOCK_LI:
            pushAttrs()
            // Tight lists have no P wrapping — set base font/color so text
            // and nested content inherit the correct style.
            currentAttrs[.font] = configuration.paragraphStyle.font
            currentAttrs[.foregroundColor] = isInsideBlockquote ? configuration.blockquoteColor : configuration.paragraphStyle.textColor
            // Determine bullet marker based on parent list type
            let isOrdered = listTypeStack.last ?? false
            let clampedDepth = min(listDepth, 6)

            var marker: String
            var isTask = false
            var taskMark: Int8 = 0
            if let detailPtr = detail?.assumingMemoryBound(to: MD_BLOCK_LI_DETAIL.self) {
                let d = detailPtr.pointee
                isTask = d.is_task != 0
                taskMark = d.task_mark
                if isOrdered {
                    if orderedListItemCounters.isEmpty { orderedListItemCounters.append(0) }
                    orderedListItemCounters[orderedListItemCounters.count - 1] += 1
                    let num = orderedListItemCounters.last ?? 1
                    marker = "\(num)."
                } else if isTask {
                    // task_mark: 'x' = checked, ' ' = unchecked
                    marker = (taskMark == 120) ? "▪" : "▫" // 120 = 'x'
                } else {
                    marker = (clampedDepth == 1) ? "•" : "◦"
                }
            } else {
                marker = isOrdered ? "1." : "•"
            }

            // Build marker attributed string with list-specific style
            let markerAttrStr: NSAttributedString
            let measuredWidth: CGFloat

            if isOrdered {
                let style = configuration.orderedListStyle
                switch style.mode {
                case .character:
                    let str = NSAttributedString(string: marker + " ", attributes: [.font: style.font, .foregroundColor: style.textColor])
                    markerAttrStr = str
                    measuredWidth = ceil(str.boundingRect(with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude), options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil).width)
                case .image:
                    if let img = style.image {
                        let markerSize = style.imageSize
                        let bounds = CGRect(x: 0, y: 0, width: markerSize.width, height: markerSize.height)
                        let model = MMarkListMarkerModel(image: img, bounds: bounds)
                        let attachment = MMarkListMarkerAttachment(attachmentType: .listMarker, content: model)
                        let str = NSMutableAttributedString(attachment: attachment)
                        str.append(NSAttributedString(string: " "))
                        markerAttrStr = str
                        measuredWidth = markerSize.width + 4
                    } else {
                        let str = NSAttributedString(string: marker + " ", attributes: [.font: style.font, .foregroundColor: style.textColor])
                        markerAttrStr = str
                        measuredWidth = ceil(str.boundingRect(with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude), options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil).width)
                    }
                }
            } else if isTask {
                let style = configuration.taskListStyle
                let isChecked = taskMark == 120
                let markerFont = isChecked ? style.checkedFont : style.uncheckedFont
                let markerColor = isChecked ? style.checkedColor : style.uncheckedColor
                switch style.mode {
                case .character:
                    let str = NSAttributedString(string: marker + " ", attributes: [.font: markerFont, .foregroundColor: markerColor])
                    markerAttrStr = str
                    measuredWidth = ceil(str.boundingRect(with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude), options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil).width)
                case .image:
                    let img = isChecked ? style.checkedImage : style.uncheckedImage
                    if let img = img {
                        let markerSize = style.imageSize
                        let bounds = CGRect(x: 0, y: 0, width: markerSize.width, height: markerSize.height)
                        let model = MMarkListMarkerModel(image: img, bounds: bounds)
                        let attachment = MMarkListMarkerAttachment(attachmentType: .listMarker, content: model)
                        let str = NSMutableAttributedString(attachment: attachment)
                        str.append(NSAttributedString(string: " "))
                        markerAttrStr = str
                        measuredWidth = markerSize.width + 4
                    } else {
                        let str = NSAttributedString(string: marker + " ", attributes: [.font: markerFont, .foregroundColor: markerColor])
                        markerAttrStr = str
                        measuredWidth = ceil(str.boundingRect(with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude), options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil).width)
                    }
                }
            } else {
                let style = configuration.unorderedListStyle
                switch style.mode {
                case .character:
                    let str = NSAttributedString(string: marker + " ", attributes: [.font: style.font, .foregroundColor: style.textColor])
                    markerAttrStr = str
                    measuredWidth = ceil(str.boundingRect(with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude), options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil).width)
                case .image:
                    let ulImg = (clampedDepth == 1) ? (style.image ?? style.secondaryImage) : (style.secondaryImage ?? style.image)
                    if let img = ulImg {
                        let markerSize = style.imageSize
                        let bounds = CGRect(x: 0, y: 0, width: markerSize.width, height: markerSize.height)
                        let model = MMarkListMarkerModel(image: img, bounds: bounds)
                        let attachment = MMarkListMarkerAttachment(attachmentType: .listMarker, content: model)
                        let str = NSMutableAttributedString(attachment: attachment)
                        str.append(NSAttributedString(string: " "))
                        markerAttrStr = str
                        measuredWidth = markerSize.width + 4
                    } else {
                        let str = NSAttributedString(string: marker + " ", attributes: [.font: style.font, .foregroundColor: style.textColor])
                        markerAttrStr = str
                        measuredWidth = ceil(str.boundingRect(with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude), options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil).width)
                    }
                }
            }

            // Calculate indentation using measured marker width
            let indentPerLevel: CGFloat = 8.0
            let baseIndent: CGFloat = 8.0
            let itemIndent = CGFloat(clampedDepth - 1) * indentPerLevel + baseIndent
            let markerWidth = max(measuredWidth, 8)

            _liStateStack.append((itemIndent, markerWidth, itemIndent + markerWidth))

            currentIndent += itemIndent
            currentHeadIndent += itemIndent + markerWidth
            containerWidth -= (itemIndent + markerWidth)

            let paraStyle = NSMutableParagraphStyle()
            paraStyle.firstLineHeadIndent = currentIndent
            paraStyle.headIndent = currentHeadIndent
            paraStyle.lineSpacing = 4

            let resultMarker = NSMutableAttributedString(attributedString: markerAttrStr)
            resultMarker.addAttribute(.paragraphStyle, value: paraStyle, range: NSRange(location: 0, length: resultMarker.length))
            if isInsideBlockquote {
                resultMarker.addAttribute(.blockquote, value: true, range: NSRange(location: 0, length: resultMarker.length))
                resultMarker.addAttribute(.blockquoteDepth, value: blockquoteDepth, range: NSRange(location: 0, length: resultMarker.length))
                resultMarker.addAttribute(.backgroundColor, value: configuration.blockquoteBackgroundColor, range: NSRange(location: 0, length: resultMarker.length))
            }

            output(resultMarker)
            isFirstItemChild = true

        case MD_BLOCK_H:
            pushAttrs()
            guard let detailPtr = detail?.assumingMemoryBound(to: MD_BLOCK_H_DETAIL.self) else {
                print("[MMarkParser] WARNING: MD_BLOCK_H detail is nil, using default heading style")
                popAttrs()
                return
            }
            let hDetail = detailPtr.pointee
            let level = Int(hDetail.level)
            let style = configuration.headingStyles[level] ?? configuration.paragraphStyle

            let paraStyle = NSMutableParagraphStyle()
            paraStyle.paragraphSpacingBefore = configuration.headingSpacingBefore[level] ?? 0
            paraStyle.paragraphSpacing = configuration.headingSpacing[level] ?? 0
            if currentHeadIndent > 0 {
                paraStyle.firstLineHeadIndent = currentHeadIndent
                paraStyle.headIndent = currentHeadIndent
            }

            currentAttrs[.font] = style.font
            currentAttrs[.foregroundColor] = style.textColor
            currentAttrs[.paragraphStyle] = paraStyle
            if isInsideBlockquote {
                currentAttrs[.blockquote] = true
                currentAttrs[.blockquoteDepth] = blockquoteDepth
                currentAttrs[.backgroundColor] = configuration.blockquoteBackgroundColor
            }

        case MD_BLOCK_P:
            pushAttrs()
            let paraStyle = NSMutableParagraphStyle()
            paraStyle.lineSpacing = 4
            if currentHeadIndent > 0 {
                paraStyle.firstLineHeadIndent = isFirstItemChild ? currentIndent : currentHeadIndent
                paraStyle.headIndent = currentHeadIndent
            }

            currentAttrs[.font] = configuration.paragraphStyle.font
            currentAttrs[.foregroundColor] = isInsideBlockquote ? configuration.blockquoteColor : configuration.paragraphStyle.textColor
            currentAttrs[.paragraphStyle] = paraStyle
            if isInsideBlockquote {
                currentAttrs[.blockquote] = true
                currentAttrs[.blockquoteDepth] = blockquoteDepth
                currentAttrs[.backgroundColor] = configuration.blockquoteBackgroundColor
            }
            isFirstItemChild = false

        case MD_BLOCK_CODE:
            pushAttrs()
            isInCodeBlock = true
            if let detailPtr = detail?.assumingMemoryBound(to: MD_BLOCK_CODE_DETAIL.self) {
                let d = detailPtr.pointee
                codeBlockLang = extractString(from: d.lang)
            }
            codeBlockContent = ""

        case MD_BLOCK_HTML:
            pushAttrs()
            // HTML blocks are skipped — text is ignored

        case MD_BLOCK_HR:
            let model = MMarkHorizontalRuleModel.create(width: containerWidth, configuration: configuration)
            let hrAttachment = MMarkHorizontalRuleAttachment(attachmentType: .horizontalRule, content: model)
            result.append(NSAttributedString(string: "\n"))
            result.append(NSAttributedString(attachment: hrAttachment))
            result.append(NSAttributedString(string: "\n\n"))

        case MD_BLOCK_TABLE:
            pushAttrs()
            if let detailPtr = detail?.assumingMemoryBound(to: MD_BLOCK_TABLE_DETAIL.self) {
                let d = detailPtr.pointee
                tableAccum = _MDTableAccumulator(
                    colCount: Int(d.col_count),
                    containerWidth: containerWidth,
                    configuration: configuration
                )
            }

        case MD_BLOCK_THEAD:
            pushAttrs()
            tableAccum?.isHeader = true

        case MD_BLOCK_TBODY:
            pushAttrs()
            tableAccum?.isHeader = false

        case MD_BLOCK_TR:
            tableAccum?.startRow()

        case MD_BLOCK_TH, MD_BLOCK_TD:
            pushAttrs()
            // Clear paragraph-level attrs; table cell uses table config font/color
            currentAttrs[.paragraphStyle] = nil
            currentAttrs[.blockquote] = nil
            currentAttrs[.blockquoteDepth] = nil
            currentAttrs[.backgroundColor] = nil
            let tableConfig = MMarkTableView.MMarkTableConfig()
            currentAttrs[.font] = (type == MD_BLOCK_TH) ? tableConfig.headerFont : tableConfig.cellFont
            currentAttrs[.foregroundColor] = tableConfig.textColor
            if let detailPtr = detail?.assumingMemoryBound(to: MD_BLOCK_TD_DETAIL.self) {
                let align = detailPtr.pointee.align
                tableAccum?.startCell(with: convertAlignment(align))
            } else {
                tableAccum?.startCell(with: .left)
            }
            // Start a fresh cell buffer
            tableAccum?.currentCellText = NSMutableAttributedString()

        case MD_BLOCK_ADMONITION:
            pushAttrs()

        case MD_BLOCK_FOOTNOTE_DEF_SECTION:
            pushAttrs()
            print("[MMarkParser] enterBlock FOOTNOTE_DEF_SECTION — start collecting footnotes")
            isCollectingFootnotes = true
            // 不在这里添加标题，等到有实际脚注定义时再添加

        case MD_BLOCK_FOOTNOTE_DEF:
            pushAttrs()
            print("[MMarkParser] enterBlock FOOTNOTE_DEF")
            isInsideFootnoteDef = true
            
            // 如果这是第一个脚注定义，添加标题和分隔线
            if footnoteBuffer.length == 0 {
                let model = MMarkHorizontalRuleModel.create(width: containerWidth, configuration: configuration)
                let hrAttachment = MMarkHorizontalRuleAttachment(attachmentType: .horizontalRule, content: model)
                footnoteBuffer.append(NSAttributedString(string: "\n"))
                footnoteBuffer.append(NSAttributedString(attachment: hrAttachment))
                footnoteBuffer.append(NSAttributedString(string: "\n"))
                let fnStyle = configuration.footnoteStyle
                let headerAttrs: [NSAttributedString.Key: Any] = [
                    .font: fnStyle.font,
                    .foregroundColor: fnStyle.textColor
                ]
                footnoteBuffer.append(NSAttributedString(string: "Footnotes", attributes: headerAttrs))
                footnoteBuffer.append(NSAttributedString(string: "\n\n"))
            }
            
            var label = ""
            if let detailPtr = detail?.assumingMemoryBound(to: MD_BLOCK_FOOTNOTE_DEF_DETAIL.self) {
                label = extractString(from: detailPtr.pointee.label)
            }
            
            print("[MMarkParser] FOOTNOTE_DEF label: \(label)")
            
            // 输出脚注标签，例如 "[1]: "
            let labelAttrs: [NSAttributedString.Key: Any] = [
                .font: configuration.footnoteReferenceStyle.font,
                .foregroundColor: configuration.footnoteReferenceStyle.textColor,
                .footnoteDef: label
            ]
            footnoteBuffer.append(NSAttributedString(string: "[\(label)]: ", attributes: labelAttrs))
            
            currentAttrs[.font] = configuration.footnoteStyle.font
            currentAttrs[.foregroundColor] = configuration.footnoteStyle.textColor
            currentAttrs[.footnoteDef] = label
            currentFootnoteDefLabel = label

        default:
            pushAttrs()
        }
    }

    func leaveBlock(_ type: MD_BLOCKTYPE, detail: UnsafeMutableRawPointer?) {
        switch type {
        case MD_BLOCK_DOC:
            popAttrs()

        case MD_BLOCK_QUOTE:
            isInsideBlockquote = blockquoteDepth > 1
            blockquoteDepth -= 1
            let borderWidth = configuration.blockquoteBorderWidth
            let spacing: CGFloat = 8.0
            let indent: CGFloat = borderWidth + spacing
            currentIndent -= indent
            currentHeadIndent -= indent
            containerWidth += indent
            result.append(NSAttributedString(string: "\n"))
            popAttrs()

        case MD_BLOCK_UL, MD_BLOCK_OL:
            listDepth -= 1
            _ = listTypeStack.popLast()
            _ = _tightListStack.popLast()
            if type == MD_BLOCK_OL { _ = orderedListItemCounters.popLast() }
            // Newlines between items handled by LI leave; no need for extra here
            popAttrs()

        case MD_BLOCK_LI:
            if let (itemIndent, markerWidth, _) = _liStateStack.popLast() {
                currentIndent -= itemIndent
                currentHeadIndent -= (itemIndent + markerWidth)
                containerWidth += itemIndent + markerWidth
            }
            // Tight lists: add \n between items (skip if already ends with \n
            // from nested list content)
            if _tightListStack.last == true {
                let currentStr = cellBuffer?.string ?? result.string
                if !currentStr.hasSuffix("\n") {
                    output("\n")
                }
            }
            popAttrs()

        case MD_BLOCK_H:
            output(NSAttributedString(string: "\n"))
            popAttrs()

        case MD_BLOCK_FOOTNOTE_DEF_SECTION:
            isCollectingFootnotes = false
            print("[MMarkParser] leaveBlock FOOTNOTE_DEF_SECTION — footnotes collected")
            popAttrs()

        case MD_BLOCK_FOOTNOTE_DEF:
            print("[MMarkParser] leaveBlock FOOTNOTE_DEF, label: \(currentFootnoteDefLabel)")
            isInsideFootnoteDef = false
            // Add ↩ backlink for navigation back to the reference
            if !currentFootnoteDefLabel.isEmpty {
                let backlinkStr = NSAttributedString(string: " ↩", attributes: [
                    .link: "footnote://ref/\(currentFootnoteDefLabel)",
                    .foregroundColor: configuration.footnoteBackrefColor,
                    .font: configuration.footnoteStyle.font
                ])
                footnoteBuffer.append(backlinkStr)
            }
            currentFootnoteDefLabel = ""
            footnoteBuffer.append(NSAttributedString(string: "\n"))
            print("[MMarkParser] footnoteBuffer after FOOTNOTE_DEF: \(footnoteBuffer.string.suffix(100))")
            popAttrs()
            popAttrs()

        case MD_BLOCK_P:
            // 在脚注定义中，段落结束不添加额外换行
            if !isInsideFootnoteDef {
                output(NSAttributedString(string: "\n\n"))
            }
            popAttrs()

        case MD_BLOCK_CODE:
            if !codeBlockContent.isEmpty {
                let trimmed = codeBlockContent.hasSuffix("\n") ? String(codeBlockContent.dropLast()) : codeBlockContent
                let lang = codeBlockLang.trimmingCharacters(in: .whitespacesAndNewlines)
                let language = lang.isEmpty ? nil : lang

                let model = MMarkCodeBlockModel.create(language: language, code: trimmed, width: containerWidth, configuration: configuration)
                let attachment = MMarkCodeBlockAttachment(attachmentType: .codeBlock, content: model)
                let attrStr = NSMutableAttributedString(attachment: attachment)

                if currentHeadIndent > 0 {
                    let ps = NSMutableParagraphStyle()
                    ps.firstLineHeadIndent = currentHeadIndent
                    ps.headIndent = currentHeadIndent
                    attrStr.addAttribute(.paragraphStyle, value: ps, range: NSRange(location: 0, length: attrStr.length))
                }
                if isInsideBlockquote {
                    attrStr.addAttribute(.blockquote, value: true, range: NSRange(location: 0, length: attrStr.length))
                    attrStr.addAttribute(.blockquoteDepth, value: blockquoteDepth, range: NSRange(location: 0, length: attrStr.length))
                    attrStr.addAttribute(.backgroundColor, value: configuration.blockquoteBackgroundColor, range: NSRange(location: 0, length: attrStr.length))
                }

                result.append(attrStr)
                result.append(NSAttributedString(string: "\n"))
            }
            isInCodeBlock = false
            codeBlockLang = ""
            codeBlockContent = ""
            popAttrs()

        case MD_BLOCK_HTML:
            popAttrs()

        case MD_BLOCK_TABLE:
            if let accum = tableAccum {
                let model = MMarkTableModel.create(
                    headerCells: accum.headerCells,
                    dataRows: accum.bodyCells,
                    alignments: accum.alignments,
                    width: containerWidth,
                    configuration: configuration
                )
                let attachment = MMarkTableAttachment(attachmentType: .table, content: model)
                let attrStr = NSMutableAttributedString(attachment: attachment)

                if currentHeadIndent > 0 {
                    let ps = NSMutableParagraphStyle()
                    ps.firstLineHeadIndent = currentHeadIndent
                    ps.headIndent = currentHeadIndent
                    attrStr.addAttribute(.paragraphStyle, value: ps, range: NSRange(location: 0, length: attrStr.length))
                }
                if isInsideBlockquote {
                    attrStr.addAttribute(.blockquote, value: true, range: NSRange(location: 0, length: attrStr.length))
                    attrStr.addAttribute(.blockquoteDepth, value: blockquoteDepth, range: NSRange(location: 0, length: attrStr.length))
                    attrStr.addAttribute(.backgroundColor, value: configuration.blockquoteBackgroundColor, range: NSRange(location: 0, length: attrStr.length))
                }

                result.append(attrStr)
                result.append(NSAttributedString(string: "\n"))
            }
            tableAccum = nil
            popAttrs()

        case MD_BLOCK_THEAD, MD_BLOCK_TBODY:
            popAttrs()

        case MD_BLOCK_TR:
            tableAccum?.endRow()

        case MD_BLOCK_TH, MD_BLOCK_TD:
            if let cellText = tableAccum?.currentCellText, cellText.length > 0 {
                tableAccum?.endCell(with: cellText)
            } else {
                tableAccum?.endCell(with: NSAttributedString())
            }
            tableAccum?.currentCellText = nil
            popAttrs()

        case MD_BLOCK_ADMONITION:
            popAttrs()

        case MD_BLOCK_HR:
            // Fully rendered in enterBlock; no attrs state to restore
            break

        default:
            popAttrs()
        }
    }

    // MARK: - Span Handlers

    func enterSpan(_ type: MD_SPANTYPE, detail: UnsafeMutableRawPointer?) {
        switch type {
        case MD_SPAN_STRONG:
            pushAttrs()
            let parentFontStrong = currentAttrs[.font] as? UIFont ?? configuration.paragraphStyle.font
            var traitsStrong = parentFontStrong.fontDescriptor.symbolicTraits
            traitsStrong.insert(.traitBold)
            if let desc = parentFontStrong.fontDescriptor.withSymbolicTraits(traitsStrong) {
                currentAttrs[.font] = UIFont(descriptor: desc, size: parentFontStrong.pointSize)
            } else {
                currentAttrs[.font] = UIFont.boldSystemFont(ofSize: parentFontStrong.pointSize)
            }
            if isInsideBlockquote, currentAttrs[.foregroundColor] == nil {
                currentAttrs[.foregroundColor] = configuration.blockquoteColor
            }

        case MD_SPAN_EM:
            pushAttrs()
            let parentFontEM = currentAttrs[.font] as? UIFont ?? configuration.paragraphStyle.font
            let emTraits = parentFontEM.fontDescriptor.symbolicTraits.union(.traitItalic)
            if let desc = parentFontEM.fontDescriptor.withSymbolicTraits(emTraits) {
                currentAttrs[.font] = UIFont(descriptor: desc, size: parentFontEM.pointSize)
                if cellBuffer != nil, let font = currentAttrs[.font] as? UIFont {
                    print("[MMarkParser] EM in table cell: italic font set: \(font)")
                }
            } else {
                currentAttrs[.font] = UIFont.italicSystemFont(ofSize: parentFontEM.pointSize)
                if cellBuffer != nil, let font = currentAttrs[.font] as? UIFont {
                    print("[MMarkParser] EM in table cell: italic fallback font: \(font)")
                }
            }
            if isInsideBlockquote, currentAttrs[.foregroundColor] == nil {
                currentAttrs[.foregroundColor] = configuration.blockquoteColor
            }

        case MD_SPAN_DEL:
            print("[MMarkParser] enterSpan DEL called")
            pushAttrs()
            currentAttrs[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
            currentAttrs[.strikethroughColor] = configuration.strikethroughColor

        case MD_SPAN_A:
            pushAttrs()
            var urlStr = ""
            if let detailPtr = detail?.assumingMemoryBound(to: MD_SPAN_A_DETAIL.self) {
                let d = detailPtr.pointee
                urlStr = extractString(from: d.href)
            }
            
            // 对 URL 进行百分比编码，防止中文等非 ASCII 字符导致桥接层 crash
            // 如果是内部锚点（以 # 开头），仅对 # 之后的部分编码
            let encodedUrl: String
            if urlStr.hasPrefix("#") {
                let anchor = String(urlStr.dropFirst())
                let encodedAnchor = anchor.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed) ?? anchor
                encodedUrl = "#" + encodedAnchor
            } else if let encoded = urlStr.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed.union(.urlPathAllowed).union(.urlHostAllowed).union(.urlFragmentAllowed)) {
                encodedUrl = encoded
            } else {
                encodedUrl = urlStr
            }
            
            let parentFont = currentAttrs[.font] as? UIFont ?? configuration.paragraphStyle.font
            currentAttrs[.font] = parentFont
            currentAttrs[.foregroundColor] = configuration.linkStyle.textColor
            currentAttrs[.underlineStyle] = configuration.linkStyle.underlineStyle.rawValue
            currentAttrs[.link] = encodedUrl

        case MD_SPAN_IMG:
            guard let detailPtr = detail?.assumingMemoryBound(to: MD_SPAN_IMG_DETAIL.self) else { return }
            let d = detailPtr.pointee
            isInImageSpan = true
            _imgAltBuffer = ""
            _imgUrlBuffer = extractString(from: d.src)
            // Don't render anything yet; alt text comes via text() callbacks.
            // On leaveSpan we'll construct ![alt](url) and render appropriately.

        case MD_SPAN_CODE:
            pushAttrs()
            let parentFont = currentAttrs[.font] as? UIFont ?? configuration.paragraphStyle.font
            let codeFont = configuration.codeStyle.font
            // Preserve bold/italic traits from parent font (bold/italic code)
            let parentTraits = parentFont.fontDescriptor.symbolicTraits
            var mergedTraits = codeFont.fontDescriptor.symbolicTraits
            if parentTraits.contains(.traitBold) { mergedTraits.insert(.traitBold) }
            if parentTraits.contains(.traitItalic) { mergedTraits.insert(.traitItalic) }
            if let mergedDesc = codeFont.fontDescriptor.withSymbolicTraits(mergedTraits) {
                currentAttrs[.font] = UIFont(descriptor: mergedDesc, size: codeFont.pointSize)
            } else {
                currentAttrs[.font] = codeFont
            }
            currentAttrs[.foregroundColor] = configuration.codeStyle.textColor
            currentAttrs[.backgroundColor] = configuration.codeStyle.backgroundColor

        case MD_SPAN_FOOTNOTE_REF:
            pushAttrs()
            var refLabel = ""
            if let detailPtr = detail?.assumingMemoryBound(to: MD_SPAN_FOOTNOTE_REF_DETAIL.self) {
                refLabel = extractString(from: detailPtr.pointee.label)
            }
            currentAttrs[.font] = configuration.footnoteReferenceStyle.font
            currentAttrs[.foregroundColor] = configuration.footnoteReferenceStyle.textColor
            currentAttrs[.backgroundColor] = configuration.footnoteReferenceStyle.backgroundColor
            currentAttrs[.footnoteRef] = refLabel
            currentAttrs[.link] = "footnote://ref/\(refLabel)"
            if isInsideBlockquote {
                currentAttrs[.blockquote] = true
                currentAttrs[.blockquoteDepth] = blockquoteDepth
                currentAttrs[.backgroundColor] = configuration.blockquoteBackgroundColor
            }
            // md4c consumes [^ and ] as syntax delimiters — output [ bracket here
            // md4c does NOT send the label text via text() callback, so render it explicitly
            if let cb = cellBuffer { cb.append(NSAttributedString(string: "[" + refLabel, attributes: currentAttrs)) }
            else { result.append(NSAttributedString(string: "[" + refLabel, attributes: currentAttrs)) }

        case MD_SPAN_LATEXMATH_DISPLAY:
            isDisplayMath = true

        case MD_SPAN_WIKILINK, MD_SPAN_U, MD_SPAN_SPOILER, MD_SPAN_SUPERSCRIPT, MD_SPAN_SUBSCRIPT:
            pushAttrs()

        default:
            pushAttrs()
        }
    }

    func leaveSpan(_ type: MD_SPANTYPE, detail: UnsafeMutableRawPointer?) {
        switch type {
        case MD_SPAN_STRONG, MD_SPAN_EM, MD_SPAN_DEL, MD_SPAN_A:
            popAttrs()

        case MD_SPAN_IMG:
            let alt = _imgAltBuffer
            let url = _imgUrlBuffer
            isInImageSpan = false
            if cellBuffer != nil {
                // Table cell: show original markdown syntax
                let text = alt.isEmpty ? url : "![\(alt)](\(url))"
                let attrStr = NSAttributedString(string: text, attributes: currentAttrs)
                cellBuffer?.append(attrStr)
            } else {
                // Normal text: render image attachment
                let model = MMarkImageModel.create(url: url, alt: alt, width: containerWidth, placeholderColor: configuration.imagePlaceholderColor)
                let attachment = MMarkImageAttachment(attachmentType: .image, content: model)
                let attrStr = NSMutableAttributedString(attachment: attachment)
                // Ensure image is on its own line to avoid TextKit 2 inline
                // attachment view positioning issues after scrolling.
                let isInlineImage = result.length > 0 && !result.string.hasSuffix("\n")
                if isInlineImage {
                    result.append(NSAttributedString(string: "\n"))
                }
                // HeadIndent paragraph style for block-level images in lists/blockquotes
                if currentHeadIndent > 0 {
                    let ps = NSMutableParagraphStyle()
                    ps.firstLineHeadIndent = currentHeadIndent
                    ps.headIndent = currentHeadIndent
                    attrStr.addAttribute(.paragraphStyle, value: ps, range: NSRange(location: 0, length: attrStr.length))
                }
                if isInsideBlockquote {
                    attrStr.addAttribute(.blockquote, value: true, range: NSRange(location: 0, length: attrStr.length))
                    attrStr.addAttribute(.blockquoteDepth, value: blockquoteDepth, range: NSRange(location: 0, length: attrStr.length))
                    attrStr.addAttribute(.backgroundColor, value: configuration.blockquoteBackgroundColor, range: NSRange(location: 0, length: attrStr.length))
                }
                result.append(attrStr)
                result.append(NSAttributedString(string: "\n"))
            }
            _imgAltBuffer = ""
            _imgUrlBuffer = ""

        case MD_SPAN_CODE:
            popAttrs()

        case MD_SPAN_FOOTNOTE_REF:
            // md4c consumes [^ and ] as syntax delimiters — output ] bracket here
            if let cb = cellBuffer { cb.append(NSAttributedString(string: "]", attributes: currentAttrs)) }
            else { output(NSAttributedString(string: "]", attributes: currentAttrs)) }
            popAttrs()

        case MD_SPAN_LATEXMATH, MD_SPAN_LATEXMATH_DISPLAY:
            isDisplayMath = false

        case MD_SPAN_WIKILINK, MD_SPAN_U, MD_SPAN_SPOILER, MD_SPAN_SUPERSCRIPT, MD_SPAN_SUBSCRIPT:
            popAttrs()

        default:
            popAttrs()
        }
    }

    // MARK: - Text Handler

    /// Returns the cell buffer if currently inside a TH/TD, nil otherwise.
    private var cellBuffer: NSMutableAttributedString? {
        return tableAccum?.currentCellText
    }

    func handleText(_ textType: MD_TEXTTYPE, text: UnsafePointer<MD_CHAR>, size: MD_SIZE) {
        switch textType {
        case MD_TEXT_NORMAL:
            let str = string(from: text, size: size)
            guard !str.isEmpty else { return }
            if isInImageSpan {
                // Accumulate alt text inside image span
                _imgAltBuffer += str
                return
            }
            if cellBuffer != nil {
                let fontName = (currentAttrs[.font] as? UIFont)?.fontName ?? "nil"
                let hasStrike = currentAttrs[.strikethroughStyle] != nil
                print("[MMarkParser] TABLE TEXT: '\(str)' font=\(fontName) strike=\(hasStrike)")
            }
            let attrStr = NSAttributedString(string: str, attributes: currentAttrs)
            if let cb = cellBuffer { cb.append(attrStr) }
            else { output(attrStr) }

        case MD_TEXT_CODE:
            let str = string(from: text, size: size)
            if isInCodeBlock {
                codeBlockContent += str
            } else {
                let attrStr = NSAttributedString(string: str, attributes: currentAttrs)
                if let cb = cellBuffer { cb.append(attrStr) }
                else { output(attrStr) }
            }

        case MD_TEXT_BR:
            let attrStr = NSAttributedString(string: "\n", attributes: currentAttrs)
            if let cb = cellBuffer { cb.append(attrStr) }
            else { output(attrStr) }

        case MD_TEXT_SOFTBR:
            let attrStr = NSAttributedString(string: "\n", attributes: currentAttrs)
            if let cb = cellBuffer { cb.append(attrStr) }
            else { output(attrStr) }

        case MD_TEXT_ENTITY:
            let entityStr = string(from: text, size: size)
            let decoded = decodeHTMLEntity(entityStr)
            let attrStr = NSAttributedString(string: decoded, attributes: currentAttrs)
            if let cb = cellBuffer { cb.append(attrStr) }
            else { output(attrStr) }

        case MD_TEXT_LATEXMATH:
            let latex = string(from: text, size: size)
            guard !latex.isEmpty else { return }
            if isDisplayMath {
                renderBlockMath(latex)
            } else {
                let rendered = renderInlineMathImage(latex: convertChemistryToLatex(latex))
                if let cb = cellBuffer { cb.append(rendered) }
                else { output(rendered) }
            }

        case MD_TEXT_HTML:
            let htmlStr = string(from: text, size: size).lowercased().trimmingCharacters(in: .whitespaces)
            if htmlStr == "<br>" || htmlStr == "<br/>" || htmlStr == "<br />" {
                let attrStr = NSAttributedString(string: "\n", attributes: currentAttrs)
                if let cb = cellBuffer { cb.append(attrStr) }
                else { output(attrStr) }
            }

        case MD_TEXT_NULLCHAR:
            break // Skip null chars

        default:
            let str = string(from: text, size: size)
            let attrStr = NSAttributedString(string: str, attributes: currentAttrs)
            if let cb = cellBuffer { cb.append(attrStr) }
            else { output(attrStr) }
        }
    }

    // MARK: - Math Rendering

    private func renderBlockMath(_ latex: String) {
        let convertedLatex = convertChemistryToLatex(latex)
        let model = MMarkMathBlockModel.create(latex: convertedLatex, width: containerWidth, configuration: configuration)
        let attachment = MMarkMathBlockAttachment(attachmentType: .mathBlock, content: model)
        let attrStr = NSMutableAttributedString(attachment: attachment)

        if let existingPS = currentAttrs[.paragraphStyle] as? NSParagraphStyle {
            attrStr.addAttribute(.paragraphStyle, value: existingPS, range: NSRange(location: 0, length: attrStr.length))
        }
        if isInsideBlockquote {
            attrStr.addAttribute(.blockquote, value: true, range: NSRange(location: 0, length: attrStr.length))
            attrStr.addAttribute(.blockquoteDepth, value: blockquoteDepth, range: NSRange(location: 0, length: attrStr.length))
            if let bg = currentAttrs[.backgroundColor] as? UIColor {
                attrStr.addAttribute(.backgroundColor, value: bg, range: NSRange(location: 0, length: attrStr.length))
            }
        }
        output(attrStr)
    }

    private func renderInlineMath(_ latex: String) {
        let convertedLatex = convertChemistryToLatex(latex)
        let rendered = self.renderInlineMathImage(latex: convertedLatex)
        result.append(rendered)
    }

    /// Convert chemistry notation (\ce{...}, \chemfig{...}) to LaTeX math
    private func convertChemistryToLatex(_ latex: String) -> String {
        var result = latex

        // Handle \chemfig{...} first
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
        } catch {}

        // Handle \ce{...}
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
        } catch {}

        return result
    }

    private func convertCeContent(_ content: String) -> String {
        var protected: [String: String] = [:]
        var counter = 0
        var result = protectLatexCommands(content, protected: &protected, counter: &counter)

        // Reaction arrows
        result = applyArrowRule(result, pattern: "->\\[([^\\]]*)\\]\\[([^\\]]*)\\]") { groups in
            let above = groups[1]; let below = groups[2]
            return "\\xrightarrow[\\text{\(below)}]{\\text{\(above)}}"
        }
        result = applyArrowRule(result, pattern: "->\\[([^\\]]*)\\]") { groups in
            return "\\xrightarrow{\\text{\(groups[1])}}"
        }
        result = result.replacingOccurrences(of: "->", with: "\\rightarrow")
        result = result.replacingOccurrences(of: "<=>", with: "\\rightleftharpoons")

        let segments = result.components(separatedBy: " + ")
        let processed = segments.map { segment -> String in
            if segment.isEmpty { return segment }
            return processCeSegment(segment, protected: protected)
        }
        result = processed.joined(separator: " + ")

        for (key, value) in protected {
            result = result.replacingOccurrences(of: key, with: value)
        }

        return result
    }

    private func protectLatexCommands(_ text: String, protected: inout [String: String], counter: inout Int) -> String {
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

    private func applyArrowRule(_ text: String, pattern: String, transform: ([String]) -> String) -> String {
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
            result = (result as NSString).replacingCharacters(in: fullRange, with: transform(groups))
        }
        return result
    }

    private func processCeSegment(_ segment: String, protected: [String: String]) -> String {
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
        if !currentFormula.isEmpty { parts.append((false, currentFormula)) }
        if inProtected && !protectedBuffer.isEmpty { parts.append((true, protectedBuffer)) }

        let processed = parts.map { part -> String in
            if part.isProtected {
                if protected.keys.contains(part.text) { return part.text }
                return convertFormulaToLatex(part.text)
            } else {
                return convertFormulaToLatex(part.text)
            }
        }
        return processed.joined()
    }

    private func convertFormulaToLatex(_ formula: String) -> String {
        if formula.hasPrefix("\\") { return formula }
        if formula.allSatisfy({ $0.isWhitespace || $0 == "+" || $0 == "=" }) { return formula }
        var s = formula
        var coefficient = ""
        while let first = s.first, first.isNumber {
            coefficient.append(first)
            s.removeFirst()
        }
        if coefficient.isEmpty && s.isEmpty { return formula }
        if s.allSatisfy({ $0.isPunctuation || $0 == "+" || $0 == "-" }) { return coefficient + s }

        var charge = ""
        if let hatIdx = s.firstIndex(of: "^") {
            let afterHat = s[s.index(after: hatIdx)...]
            if afterHat.hasPrefix("{") {
                let fromIdx = s.index(after: hatIdx)
                let afterOpen = s.index(after: fromIdx)
                if let closeIdx = s[afterOpen...].firstIndex(of: "}") {
                    charge = String(s[hatIdx...closeIdx])
                    s = String(s[..<hatIdx])
                }
            } else {
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

        if charge.isEmpty, let last = s.last, last == "+" || last == "-" {
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

        do {
            let subPattern = try NSRegularExpression(pattern: "([A-Za-z\\)\\]])(\\d+)")
            let subMatches = subPattern.matches(in: s, range: NSRange(location: 0, length: s.utf16.count))
            for match in subMatches.reversed() {
                let fullRange = match.range(at: 0)
                let letter = (s as NSString).substring(with: match.range(at: 1))
                let digits = (s as NSString).substring(with: match.range(at: 2))
                s = (s as NSString).replacingCharacters(in: fullRange, with: "\(letter)_{\(digits)}")
            }
        } catch {}

        if !s.isEmpty {
            let body = "\\mathrm{\(s)}"
            return coefficient + body + charge
        } else if !charge.isEmpty {
            return coefficient + charge
        }
        return coefficient + s + charge
    }

    private func renderInlineMathImage(latex: String) -> NSAttributedString {
        return DispatchQueue.mainSyncSafe { [weak self] in
            guard let self = self else { return NSAttributedString(string: latex) }
            
            let label = MTMathUILabel()
            label.latex = latex
            label.mode = .text
            if let mathFont = self.configuration.mathDisplayFont {
                label.font = mathFont
            } else {
                label.fontSize = self.configuration.mathInlineStyle.font.pointSize
            }
            label.textColor = self.configuration.mathInlineStyle.textColor
            label.contentInsets = .zero
            label.sizeToFit()

            let labelSize = label.frame.size
            guard labelSize.width > 0 && labelSize.height > 0 else {
                let style = self.configuration.mathInlineStyle
                return NSAttributedString(string: latex, attributes: [
                    .font: style.font,
                    .foregroundColor: style.textColor,
                    .backgroundColor: style.backgroundColor
                ])
            }

            let renderer = UIGraphicsImageRenderer(size: labelSize)
            let image = renderer.image { ctx in
                UIColor.clear.setFill()
                ctx.fill(CGRect(origin: .zero, size: labelSize))
                ctx.cgContext.translateBy(x: 0, y: labelSize.height)
                ctx.cgContext.scaleBy(x: 1, y: -1)
                label.layer.render(in: ctx.cgContext)
            }

            let attachment = NSTextAttachment()
            attachment.image = image
            let font = self.configuration.paragraphStyle.font
            let capHeight = font.capHeight
            let imageHeight = labelSize.height
            let descent = (imageHeight - capHeight) / 2
            attachment.bounds = CGRect(x: 0, y: -descent, width: labelSize.width, height: imageHeight)
            return NSAttributedString(attachment: attachment)
        }
    }

    // MARK: - Helpers

    private func string(from ptr: UnsafePointer<MD_CHAR>?, size: MD_SIZE) -> String {
        guard size > 0, let ptr = ptr else { return "" }
        // MD_CHAR is Int8; rebind to UInt8 for UTF-8 decoding
        let uint8Ptr = UnsafeRawPointer(ptr).assumingMemoryBound(to: UInt8.self)
        let buffer = UnsafeBufferPointer(start: uint8Ptr, count: Int(size))
        guard let string = String(bytes: buffer, encoding: .utf8) else {
            print("[MMarkParser] WARNING: Failed to decode UTF-8 string from pointer")
            return ""
        }
        return string
    }

    private func extractString(from attr: MD_ATTRIBUTE) -> String {
        guard attr.size > 0, let ptr = attr.text else { return "" }
        // MD_CHAR is Int8; rebind to UInt8 for UTF-8 decoding
        let uint8Ptr = UnsafeRawPointer(ptr).assumingMemoryBound(to: UInt8.self)
        let buffer = UnsafeBufferPointer(start: uint8Ptr, count: Int(attr.size))
        guard let string = String(bytes: buffer, encoding: .utf8) else {
            print("[MMarkParser] WARNING: Failed to decode UTF-8 string from MD_ATTRIBUTE")
            return ""
        }
        return string
    }

    private func convertAlignment(_ align: MD_ALIGN) -> NSTextAlignment {
        switch align {
        case MD_ALIGN_LEFT:   return .left
        case MD_ALIGN_CENTER: return .center
        case MD_ALIGN_RIGHT:  return .right
        default:              return .left
        }
    }

    /// Decode HTML entity string to its character representation.
    private func decodeHTMLEntity(_ entity: String) -> String {
        guard !entity.isEmpty else { return "" }
        // Handle common HTML entities
        let commonEntities: [String: String] = [
            "&amp;": "&", "&lt;": "<", "&gt;": ">",
            "&quot;": "\"", "&apos;": "'", "&nbsp;": "\u{00A0}",
            "&ndash;": "\u{2013}", "&mdash;": "\u{2014}", "&hellip;": "\u{2026}",
            "&lsquo;": "\u{2018}", "&rsquo;": "\u{2019}",
            "&ldquo;": "\u{201C}", "&rdquo;": "\u{201D}"
        ]
        if let decoded = commonEntities[entity] {
            return decoded
        }
        // Handle numeric entities (&#1234; and &#x1F600;)
        if entity.hasPrefix("&#") {
            let numericPart = entity
                .replacingOccurrences(of: "&#", with: "")
                .replacingOccurrences(of: ";", with: "")
            if numericPart.hasPrefix("x") || numericPart.hasPrefix("X") {
                // Hex entity
                let hexStr = String(numericPart.dropFirst())
                if let codePoint = UInt32(hexStr, radix: 16),
                   let scalar = UnicodeScalar(codePoint) {
                    return String(scalar)
                }
            } else {
                // Decimal entity
                if let codePoint = UInt32(numericPart),
                   let scalar = UnicodeScalar(codePoint) {
                    return String(scalar)
                }
            }
        }
        return entity
    }

}

// MARK: - Table Accumulator

/// Accumulates table structure from md4c row-by-row callbacks.
@available(iOS 15.0, *)
private final class _MDTableAccumulator {
    let colCount: Int
    let containerWidth: CGFloat
    let configuration: MMarkStyleConfiguration
    var alignments: [NSTextAlignment] = []
    var headerCells: [NSAttributedString] = []
    var bodyCells: [[NSAttributedString]] = []
    var isHeader = false

    // Current row/cell state
    var currentRow: [NSAttributedString] = []
    var currentCellText: NSMutableAttributedString?

    private var textBuffer = NSMutableAttributedString()

    init(colCount: Int, containerWidth: CGFloat, configuration: MMarkStyleConfiguration) {
        self.colCount = colCount
        self.containerWidth = containerWidth
        self.configuration = configuration
    }

    func startRow() {
        currentRow = []
    }

    func endRow() {
        guard !currentRow.isEmpty else { return }
        if isHeader {
            headerCells = currentRow
        } else {
            bodyCells.append(currentRow)
        }
        currentRow = []
    }

    func startCell(with alignment: NSTextAlignment) {
        if alignments.count < colCount {
            alignments.append(alignment)
        }
        currentCellText = NSMutableAttributedString()
    }

    func endCell(with text: NSAttributedString) {
        currentRow.append(text)
    }
}

// MARK: - C Callback Function Pointers

private let mdEnterBlock: @convention(c) (
    MD_BLOCKTYPE, UnsafeMutableRawPointer?, UnsafeMutableRawPointer?
) -> Int32 = { type, detail, userdata in
    guard let userdata = userdata else {
        print("[MMarkParser] ERROR: mdEnterBlock received nil userdata")
        return -1
    }
    let handler = Unmanaged<_MD4CHandler>.fromOpaque(userdata).takeUnretainedValue()
    handler.enterBlock(type, detail: detail)
    return 0
}

private let mdLeaveBlock: @convention(c) (
    MD_BLOCKTYPE, UnsafeMutableRawPointer?, UnsafeMutableRawPointer?
) -> Int32 = { type, detail, userdata in
    guard let userdata = userdata else {
        print("[MMarkParser] ERROR: mdLeaveBlock received nil userdata")
        return -1
    }
    let handler = Unmanaged<_MD4CHandler>.fromOpaque(userdata).takeUnretainedValue()
    handler.leaveBlock(type, detail: detail)
    return 0
}

private let mdEnterSpan: @convention(c) (
    MD_SPANTYPE, UnsafeMutableRawPointer?, UnsafeMutableRawPointer?
) -> Int32 = { type, detail, userdata in
    guard let userdata = userdata else {
        print("[MMarkParser] ERROR: mdEnterSpan received nil userdata")
        return -1
    }
    let handler = Unmanaged<_MD4CHandler>.fromOpaque(userdata).takeUnretainedValue()
    handler.enterSpan(type, detail: detail)
    return 0
}

private let mdLeaveSpan: @convention(c) (
    MD_SPANTYPE, UnsafeMutableRawPointer?, UnsafeMutableRawPointer?
) -> Int32 = { type, detail, userdata in
    guard let userdata = userdata else {
        print("[MMarkParser] ERROR: mdLeaveSpan received nil userdata")
        return -1
    }
    let handler = Unmanaged<_MD4CHandler>.fromOpaque(userdata).takeUnretainedValue()
    handler.leaveSpan(type, detail: detail)
    return 0
}

private let mdText: @convention(c) (
    MD_TEXTTYPE, UnsafePointer<MD_CHAR>?, MD_SIZE, UnsafeMutableRawPointer?
) -> Int32 = { textType, text, size, userdata in
    guard let userdata = userdata, let text = text else { return 0 }
    let handler = Unmanaged<_MD4CHandler>.fromOpaque(userdata).takeUnretainedValue()
    handler.handleText(textType, text: text, size: size)
    return 0
}

// MARK: - MMarkParserWrapper

/// Swift wrapper for md4c - SAX callback driven markdown to NSAttributedString conversion.
@available(iOS 15.0, *)
@MainActor
public final class MMarkParserWrapper {

    nonisolated(unsafe) private static var lastErrorMessage: String = ""

    public static var lastError: String {
        return lastErrorMessage
    }

    private static let initializeOnce: Void = {
        MMarkFontLoader.ensureFontsRegistered()
    }()

    /// Convert Markdown to NSAttributedString using md4c SAX callbacks.
    public static func markdown(toAttributedString markdown: String,
                               options: UInt32,
                               configuration: MMarkStyleConfiguration = .defaultStyle,
                               containerWidth: CGFloat = UIScreen.main.bounds.width - 32) -> NSAttributedString? {
        _ = initializeOnce

        guard !markdown.isEmpty else {
            lastErrorMessage = "Input markdown is empty"
            return NSAttributedString()
        }

        let handler = _MD4CHandler(configuration: configuration, containerWidth: containerWidth)

        // Build md4c flags: default GFM flags + user options
        var flags = options
        // Always enable permissive autolinks for GFM compatibility
        // (already included in default .gfm options)

        var parser = MD_PARSER(
            abi_version: 0,
            flags: flags,
            enter_block: mdEnterBlock,
            leave_block: mdLeaveBlock,
            enter_span: mdEnterSpan,
            leave_span: mdLeaveSpan,
            text: mdText,
            debug_log: nil,
            syntax: nil
        )

        let utf8 = markdown.utf8CString
        let userdata = Unmanaged.passUnretained(handler).toOpaque()

        let parseResult = utf8.withUnsafeBufferPointer { buffer -> Int32 in
            guard let base = buffer.baseAddress else { return -1 }
            return md_parse(base, MD_SIZE(markdown.utf8.count), &parser, userdata)
        }

        guard parseResult == 0 else {
            lastErrorMessage = "md4c parsing failed with code \(parseResult)"
            return nil
        }

        lastErrorMessage = ""
        
        // Append collected footnotes to the end of the document
        if handler.footnoteBuffer.length > 0 {
            handler.result.append(handler.footnoteBuffer)
        }
        
        return handler.result
    }
}
