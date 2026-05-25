import UIKit

/// A UITextView subclass that renders Markdown with blockquote bars, link handling, and attachment views.
@available(iOS 15.0, *)
@MainActor
public class MMarkTextView: UITextView, UITextViewDelegate, MMarkTextComponent {

    /// The style configuration applied to parsed Markdown.
    public var styleConfiguration: MMarkStyleConfiguration = .defaultStyle

    /// A delegate that receives link-tap callbacks.
    public weak var mmarkLinkDelegate: MMarkLinkDelegate?

    internal var isUpdatingBars = false

    public convenience init() {
        self.init(frame: .zero, textContainer: nil)
    }

    public override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        commonInit()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        self.isEditable = false
        self.isScrollEnabled = true
        self.backgroundColor = .systemBackground
        self.delegate = self
        self.linkTextAttributes = [:]
        registerCommonViewProviders()
    }

    /// 设置 Markdown 内容
    public func setMarkdown(_ markdown: String) {
        let parser = CMarkParser()
        let attributedString: NSAttributedString
        do {
            attributedString = try parser.parse(markdown, configuration: styleConfiguration)
        } catch {
            attributedString = NSAttributedString(string: markdown)
        }
        self.attributedText = attributedString
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

// MARK: - Link Handling (UITextViewDelegate)

@available(iOS 15.0, *)
extension MMarkTextView {
    public func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        return self.handleCommonLink(URL, in: textView)
    }
}

// MARK: - Blockquote Bar Rendering

@available(iOS 15.0, *)
extension MMarkTextView {
    internal func updateBlockquoteBars() {
        renderBlockquoteBars(isUpdating: &isUpdatingBars, subviews: subviews)
    }
}
