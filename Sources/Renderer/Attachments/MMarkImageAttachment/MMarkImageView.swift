import UIKit
import Kingfisher

// MARK: - MMarkImageView

@available(iOS 15.0, *)
public final class MMarkImageView: UIView {

    public let url: String
    public let alt: String
    public let targetSize: CGSize

    private let imageView = UIImageView()
    private let activityIndicator = UIActivityIndicatorView(style: .medium)

    public override init(frame: CGRect) {
        self.url = ""
        self.alt = ""
        self.targetSize = .zero
        super.init(frame: frame)
        setupView()
    }

    public init(size: CGSize, url: String, alt: String) {
        self.url = url
        self.alt = alt
        self.targetSize = size
        super.init(frame: CGRect(origin: .zero, size: size))
        setupView()
        loadImage()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        clipsToBounds = true
        translatesAutoresizingMaskIntoConstraints = false

        backgroundColor = UIColor.systemGray5

        imageView.contentMode = .scaleToFill
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(imageView)

        activityIndicator.hidesWhenStopped = true
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),

            activityIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    private static let sharedPlaceholder: UIImage = {
        let size = CGSize(width: 200, height: 150)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            UIColor.systemGray5.setFill()
            ctx.cgContext.fill(CGRect(origin: .zero, size: size))

            let iconSize: CGFloat = min(size.width, size.height) * 0.3
            let iconRect = CGRect(
                x: (size.width - iconSize) / 2,
                y: (size.height - iconSize) / 2,
                width: iconSize,
                height: iconSize
            )
            ctx.cgContext.setStrokeColor(UIColor.systemGray.cgColor)
            ctx.cgContext.setLineWidth(2)
            ctx.cgContext.stroke(iconRect)

            ctx.cgContext.move(to: CGPoint(x: iconRect.minX, y: iconRect.minY))
            ctx.cgContext.addLine(to: CGPoint(x: iconRect.maxX, y: iconRect.maxY))
            ctx.cgContext.move(to: CGPoint(x: iconRect.maxX, y: iconRect.minY))
            ctx.cgContext.addLine(to: CGPoint(x: iconRect.minX, y: iconRect.maxY))
            ctx.cgContext.strokePath()
        }
    }()

    private func loadImage() {
        guard let imageURL = URL(string: url), targetSize.width > 0, targetSize.height > 0 else {
            showPlaceholder()
            return
        }

        activityIndicator.startAnimating()

        // Kingfisher 处理器：先 aspectFill 填充到目标尺寸，再居中裁剪到精确尺寸
        // 确保图片按 4:3 宽高比显示，不会被拉伸
        let processor = ResizingImageProcessor(referenceSize: targetSize, mode: .aspectFill)
                     |> CroppingImageProcessor(size: targetSize)

        imageView.kf.setImage(
            with: imageURL,
            placeholder: createPlaceholder(),
            options: [
                .processor(processor),
                .scaleFactor(UIScreen.main.scale),
                .cacheOriginalImage,
                .transition(.fade(0.25))
            ],
            completionHandler: { [weak self] _ in
                DispatchQueue.main.async {
                    self?.activityIndicator.stopAnimating()
                }
            }
        )
    }

    private func createPlaceholder() -> UIImage {
        Self.sharedPlaceholder
    }

    private func showPlaceholder() {
        imageView.image = Self.sharedPlaceholder
        activityIndicator.stopAnimating()
    }

    public override var intrinsicContentSize: CGSize {
        return targetSize
    }
}