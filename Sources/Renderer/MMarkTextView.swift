import UIKit

/// 最简化的 MMarkTextView，只保留 markdown 解析渲染
@available(iOS 15.0, *)
public class MMarkTextView: UITextView {

    /// 样式配置
    public var styleConfiguration: MMarkStyleConfiguration = .defaultStyle

    private var isUpdatingBars = false

    public override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        self.isEditable = false
        self.isScrollEnabled = true
        self.backgroundColor = .systemBackground
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.isEditable = false
        self.isScrollEnabled = true
        self.backgroundColor = .systemBackground
    }

    /// 设置 Markdown 内容
    public func setMarkdown(_ markdown: String) {
        NSTextAttachment.registerViewProviderClass(MMarkCodeBlockViewProvider.self, forFileType: MMarkCodeBlockAttachment.codeBlockFileType)
        NSTextAttachment.registerViewProviderClass(MMarkTableViewProvider.self, forFileType: MMarkTableAttachment.tableFileType)
        NSTextAttachment.registerViewProviderClass(MMarkMathBlockViewProvider.self, forFileType: MMarkMathBlockAttachment.mathBlockFileType)
        NSTextAttachment.registerViewProviderClass(MMarkImageViewProvider.self, forFileType: MMarkImageAttachment.imageFileType)
        let parser = CMarkParser()
        let attributedString: NSAttributedString
        do {
            attributedString = try parser.parse(markdown, configuration: styleConfiguration)
        } catch {
            attributedString = NSAttributedString(string: markdown)
        }
        self.attributedText = attributedString
        // Bar update is triggered by contentSize.didSet when TextKit 2 finishes layout
    }

    /// 监听 contentSize 变化，在 TextKit 2 布局完成后更新引用块竖条。
    public override var contentSize: CGSize {
        didSet {
            if oldValue != contentSize {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.updateBlockquoteBars()
                }
            }
        }
    }
}

// MARK: - Blockquote Bar Rendering

@available(iOS 15.0, *)
extension MMarkTextView {
    /// Marker class for blockquote bar views, used to find and remove existing bars on each layout pass
    private class MMarkBlockquoteBarView: UIView {}

    private func updateBlockquoteBars() {
        // Prevent re-entrant calls
        guard !isUpdatingBars else { return }
        isUpdatingBars = true
        defer { isUpdatingBars = false }

        // Remove existing bar views before recreating
        subviews.filter { $0 is MMarkBlockquoteBarView }.forEach { $0.removeFromSuperview() }

        guard let attributedText = self.attributedText else { return }

        let fullRange = NSRange(location: 0, length: attributedText.length)

        // Step 1: Collect all (range, depth, headIndent) tuples
        var blockquoteSections: [(range: NSRange, depth: Int, headIndent: CGFloat)] = []

        attributedText.enumerateAttribute(.blockquote, in: fullRange) { value, range, stop in
            guard value != nil else { return }

            let depth = attributedText.attribute(.blockquoteDepth, at: range.location, effectiveRange: nil) as? Int ?? 1
            let headIndent: CGFloat = {
                var indent: CGFloat = 0
                attributedText.enumerateAttribute(.paragraphStyle, in: range, options: []) { value, attrRange, stop in
                    if let ps = value as? NSParagraphStyle {
                        indent = ps.headIndent
                        stop.pointee = true
                    }
                }
                if indent == 0, let d = attributedText.attribute(.blockquoteDepth, at: range.location, effectiveRange: nil) as? Int {
                    indent = CGFloat(d * 20)
                }
                return indent
            }()

            blockquoteSections.append((range, depth, headIndent))
        }

        guard !blockquoteSections.isEmpty else { return }

        // Step 2: Sort by location, then merge consecutive same-depth sections
        blockquoteSections.sort { $0.range.location < $1.range.location }

        var mergedSections: [(range: NSRange, depth: Int, headIndent: CGFloat)] = []

        for section in blockquoteSections {
            if var last = mergedSections.last, last.depth == section.depth {
                let gap = section.range.location - (last.range.location + last.range.length)
                if gap >= 0 && gap <= 5 {
                    let mergedRange = NSRange(
                        location: last.range.location,
                        length: section.range.location + section.range.length - last.range.location
                    )
                    last.range = mergedRange
                    mergedSections[mergedSections.count - 1] = last
                    continue
                }
            }
            mergedSections.append(section)
        }

        // Step 3: Create one continuous bar per merged section
        for section in mergedSections {
            let range = section.range
            let headIndent = section.headIndent

            guard let start = position(from: beginningOfDocument, offset: range.location),
                  let end = position(from: start, offset: range.length),
                  let rangeText = textRange(from: start, to: end) else { return }

            let firstLineRect = firstRect(for: rangeText)
            guard !firstLineRect.isNull, firstLineRect.height > 0 else { return }

            // Calculate bottom Y using the last meaningful character's rect
            let lastCharOffset = range.location + range.length - 1
            let lastChar = (attributedText.string as NSString).substring(with: NSRange(location: lastCharOffset, length: 1))
            let isNewline = lastChar == "\n" || lastChar == "\r"
            let effectiveOffset = isNewline ? max(range.location, lastCharOffset - 1) : lastCharOffset

            var bottomY = firstLineRect.maxY
            if effectiveOffset >= range.location,
               let lastPos = position(from: beginningOfDocument, offset: effectiveOffset),
               let lastEnd = position(from: lastPos, offset: 1),
               let lastRange = textRange(from: lastPos, to: lastEnd) {
                let lastRect = firstRect(for: lastRange)
                if !lastRect.isNull, !lastRect.isEmpty {
                    bottomY = lastRect.maxY
                }
            }

            let topY = firstLineRect.minY
            let height = bottomY - topY
            guard height > 0 else { return }

            // Position the bar at the left edge of the blockquote text area.
            let barX = textContainerInset.left + headIndent - styleConfiguration.blockquoteBorderWidth
            let barY = topY

            let barView = MMarkBlockquoteBarView(frame: CGRect(
                x: barX,
                y: barY,
                width: styleConfiguration.blockquoteBorderWidth,
                height: height
            ))
            barView.backgroundColor = styleConfiguration.blockquoteBorderColor
            barView.isUserInteractionEnabled = false
            self.addSubview(barView)
        }
    }
}