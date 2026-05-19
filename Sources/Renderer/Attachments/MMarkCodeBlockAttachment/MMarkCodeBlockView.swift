import UIKit

// MARK: - MMarkCodeBlockView

@available(iOS 15.0, *)
public final class MMarkCodeBlockView: UIView {

    public var language: String?
    public var code: String = ""
    public var configuration: MMarkStyleConfiguration = .defaultStyle

    // MARK: - Config

    public struct MMarkCodeBlockConfig {
        public var headerBackgroundColor: UIColor = UIColor.systemGray.withAlphaComponent(0.3)
        public var bodyBackgroundColor: UIColor = UIColor.systemGray.withAlphaComponent(0.1)
        public var cornerRadius: CGFloat = 12
        public var headerHeight: CGFloat = 32
        public var padding: CGFloat = 12
        public var copyButtonWidth: CGFloat = 60

        public init() {}
    }

    public var config: MMarkCodeBlockConfig = .init()

    // MARK: - Subviews

    private let headerView = UIView()
    private let languageLabel = UILabel()
    private let copyButton = UIButton(type: .system)
    private let codeScrollView = UIScrollView()
    private let codeTextView = UITextView()

    private var codeTextHeightConstraint: NSLayoutConstraint?
    private var codeTextWidthConstraint: NSLayoutConstraint?

    // MARK: - Init

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    public convenience init(model: MMarkCodeBlockModel, configuration: MMarkStyleConfiguration = .defaultStyle) {
        self.init(frame: CGRect(origin: .zero, size: model.size))
        self.language = model.language
        self.code = model.code
        self.configuration = configuration
        self.codeTextView.attributedText = model.highlightedCode
        self.languageLabel.text = language ?? "Code"
        codeTextWidthConstraint?.constant = model.codeTextWidth
        codeTextHeightConstraint?.constant = model.codeTextHeight
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupViews() {
        backgroundColor = config.bodyBackgroundColor
        layer.cornerRadius = config.cornerRadius
        clipsToBounds = true
        translatesAutoresizingMaskIntoConstraints = false

        // Header
        headerView.backgroundColor = config.headerBackgroundColor
        headerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(headerView)

        // Language label
        languageLabel.text = language ?? "Code"
        languageLabel.font = .systemFont(ofSize: 12, weight: .medium)
        languageLabel.textColor = .label
        languageLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(languageLabel)

        // Copy button
        copyButton.setTitle("Copy", for: .normal)
        copyButton.titleLabel?.font = .systemFont(ofSize: 12, weight: .regular)
        copyButton.addTarget(self, action: #selector(copyCode), for: .touchUpInside)
        copyButton.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(copyButton)

        // Code scroll view
        codeScrollView.showsHorizontalScrollIndicator = true
        codeScrollView.showsVerticalScrollIndicator = false
        codeScrollView.backgroundColor = .clear
        codeScrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(codeScrollView)

        // Code text view
        codeTextView.isEditable = false
        codeTextView.isSelectable = true
        codeTextView.isScrollEnabled = false
        codeTextView.backgroundColor = .clear
        codeTextView.textContainerInset = .zero
        codeTextView.textContainer.lineFragmentPadding = 0
        codeTextView.setContentCompressionResistancePriority(.required, for: .vertical)
        codeTextView.setContentCompressionResistancePriority(.required, for: .horizontal)
        codeTextView.translatesAutoresizingMaskIntoConstraints = false
        codeScrollView.addSubview(codeTextView)

        setupConstraints()
    }

    private func setupConstraints() {
        let padding = config.padding
        let headerHeight = config.headerHeight

        NSLayoutConstraint.activate([
            // headerView
            headerView.topAnchor.constraint(equalTo: topAnchor),
            headerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: headerHeight),

            // languageLabel - vertical center in header
            languageLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            languageLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: padding),

            // copyButton - vertical center in header
            copyButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            copyButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -padding),
            copyButton.widthAnchor.constraint(equalToConstant: config.copyButtonWidth),

            // codeScrollView
            codeScrollView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: padding),
            codeScrollView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
            codeScrollView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding),
            codeScrollView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -padding),

            // codeTextView pinned to scroll view content layout guide
            codeTextView.topAnchor.constraint(equalTo: codeScrollView.contentLayoutGuide.topAnchor),
            codeTextView.leadingAnchor.constraint(equalTo: codeScrollView.contentLayoutGuide.leadingAnchor),
            codeTextView.bottomAnchor.constraint(equalTo: codeScrollView.contentLayoutGuide.bottomAnchor),
            codeTextView.trailingAnchor.constraint(equalTo: codeScrollView.contentLayoutGuide.trailingAnchor),
        ])

        // Code text width constraint - set from model's codeTextWidth
        codeTextWidthConstraint = codeTextView.widthAnchor.constraint(equalToConstant: 0)
        codeTextWidthConstraint?.priority = .required
        codeTextWidthConstraint?.isActive = true

        // Code text height constraint - set from model's codeTextHeight
        codeTextHeightConstraint = codeTextView.heightAnchor.constraint(equalToConstant: 0)
        codeTextHeightConstraint?.priority = .required
        codeTextHeightConstraint?.isActive = true
    }

    static func highlightedCode(language: String?, code: String, configuration: MMarkStyleConfiguration) -> NSAttributedString {
        let style = configuration.codeBlockStyle
        let font = Font(size: Double(style.font.pointSize))

        guard let lang = language, !lang.isEmpty else {
            return NSAttributedString(string: code, attributes: [
                .font: style.font,
                .foregroundColor: style.textColor
            ])
        }

        let theme = Theme.sundellsColors(withFont: font)
        let format = AttributedStringOutputFormat(theme: theme)
        let highlighter = SyntaxHighlighter(format: format, grammar: SwiftGrammar())
        return highlighter.highlight(code)
    }

    // MARK: - Layout

    public override var intrinsicContentSize: CGSize {
        return CGSize(width: frame.width, height: frame.height)
    }

    @objc private func copyCode() {
        UIPasteboard.general.string = code
    }
}