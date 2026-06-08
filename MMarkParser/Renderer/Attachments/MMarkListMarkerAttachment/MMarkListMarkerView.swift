import UIKit

// MARK: - MMarkListMarkerView

@available(iOS 15.0, *)
public final class MMarkListMarkerView: UIView {

    private let imageView = UIImageView()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    public convenience init(model: MMarkListMarkerModel) {
        self.init(frame: CGRect(origin: .zero, size: model.bounds.size))
        imageView.image = model.image
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
