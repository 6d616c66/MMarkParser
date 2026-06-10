import UIKit
import BeautifulMermaidSwift

// MARK: - MMarkMermaidView

@available(iOS 15.0, *)
public class MMarkMermaidView: UIView {

    // MARK: - Subviews

    private let headerView = UIView()
    private let titleLabel = UILabel()
    private let copyButton = UIButton(type: .system)
    private let scrollView = UIScrollView()
    private let imageView = UIImageView()

    private let configuration: MMarkStyleConfiguration

    /// 图片内容宽度约束
    private var imageWidthConstraint: NSLayoutConstraint?
    /// 图片内容高度约束
    private var imageHeightConstraint: NSLayoutConstraint?
    /// ScrollView 高度约束
    private var scrollViewHeightConstraint: NSLayoutConstraint?
    /// ScrollView 宽度约束
    private var scrollViewWidthConstraint: NSLayoutConstraint?

    /// 源码文本，供复制按钮使用
    public var source: String = ""

    // MARK: - Init

    public init(model: MMarkMermaidModel, configuration: MMarkStyleConfiguration = .defaultStyle) {
        self.configuration = configuration
        self.source = model.source
        super.init(frame: .zero)
        setupViews(with: model)
    }

    required init?(coder: NSCoder) {
        self.configuration = .defaultStyle
        super.init(coder: coder)
    }

    // MARK: - Setup

    private func setupViews(with model: MMarkMermaidModel) {
        let padding = configuration.mermaidStyle.padding
        let cornerRadius = configuration.mermaidStyle.cornerRadius
        let headerHeight = configuration.mermaidStyle.headerHeight

        backgroundColor = configuration.mermaidStyle.backgroundColor
        layer.cornerRadius = cornerRadius
        clipsToBounds = true

        // Header
        headerView.backgroundColor = configuration.mermaidStyle.headerBackgroundColor
        headerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(headerView)

        // Title label
        titleLabel.text = model.isError ? "Mermaid (Error)" : model.diagramTypeName
        titleLabel.font = .systemFont(ofSize: 12, weight: .medium)
        titleLabel.textColor = .secondaryLabel
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(titleLabel)

        // Copy button
        copyButton.setTitle("Copy", for: .normal)
        copyButton.titleLabel?.font = .systemFont(ofSize: 12, weight: .regular)
        copyButton.addTarget(self, action: #selector(copySource), for: .touchUpInside)
        copyButton.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(copyButton)

        // ScrollView（横向滚动容器）
        scrollView.showsHorizontalScrollIndicator = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.backgroundColor = .clear
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        // 对齐图片 scale，避免非 2x 设备模糊
        if model.image.scale > 0 {
            scrollView.contentScaleFactor = model.image.scale
        }
        addSubview(scrollView)

        // ImageView（使用图片自然尺寸，支持横向滚动）
        imageView.image = model.image
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = nil
        imageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.required, for: .vertical)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(imageView)

        setupConstraints(
            headerHeight: headerHeight,
            padding: padding,
            containerWidth: model.size.width,
            imageWidth: model.imageWidth,
            imageHeight: model.imageHeight
        )
    }

    private func setupConstraints(headerHeight: CGFloat, padding: CGFloat, containerWidth: CGFloat, imageWidth: CGFloat, imageHeight: CGFloat) {
        NSLayoutConstraint.activate([
            // headerView
            headerView.topAnchor.constraint(equalTo: topAnchor),
            headerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: headerHeight),

            // titleLabel
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: padding),

            // copyButton
            copyButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            copyButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -padding),

            // scrollView (header 下方，左侧 padding)
            scrollView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: padding),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),

            // imageView pinned to scrollView contentLayoutGuide
            imageView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            imageView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            imageView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor)
        ])

        // ScrollView 显式尺寸约束（不依赖 self.bottom/trailing，避免 TextKit 2 设 frame 时 Auto Layout 求解为 0）
        let scrollViewWidth = max(0, containerWidth - padding * 2)
        scrollViewWidthConstraint = scrollView.widthAnchor.constraint(equalToConstant: scrollViewWidth)
        scrollViewWidthConstraint?.isActive = true
        scrollViewHeightConstraint = scrollView.heightAnchor.constraint(equalToConstant: imageHeight)
        scrollViewHeightConstraint?.isActive = true

        // 图片自然尺寸约束（与代码块的 codeTextWidth/codeTextHeight 一致）
        imageWidthConstraint = imageView.widthAnchor.constraint(equalToConstant: imageWidth)
        imageWidthConstraint?.priority = .required
        imageWidthConstraint?.isActive = true

        imageHeightConstraint = imageView.heightAnchor.constraint(equalToConstant: imageHeight)
        imageHeightConstraint?.priority = .required
        imageHeightConstraint?.isActive = true
    }

    // MARK: - Public

    /// 更新图片（暗黑模式重渲染时调用）
    public func updateImage(_ newImage: UIImage) {
        imageView.image = newImage
        imageWidthConstraint?.constant = newImage.size.width
        imageHeightConstraint?.constant = newImage.size.height
        // scrollViewHeight 跟随图片高度变化
        scrollViewHeightConstraint?.constant = newImage.size.height
        // scrollViewWidth 保持容器可见宽度，不随图片宽度变化
        // 对齐图片 scale
        if newImage.scale > 0 {
            scrollView.contentScaleFactor = newImage.scale
        }
    }

    // MARK: - Actions

    @objc private func copySource() {
        UIPasteboard.general.string = source
    }

    // MARK: - Trait Collection

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle {
            NotificationCenter.default.post(name: .MMarkMermaidNeedsRerender, object: self)
        }
    }
}

// MARK: - Notification

@available(iOS 15.0, *)
extension Notification.Name {
    /// Mermaid 图表需要重新渲染（暗黑模式切换等场景）
    public static let MMarkMermaidNeedsRerender = Notification.Name("MMarkMermaidNeedsRerender")
}