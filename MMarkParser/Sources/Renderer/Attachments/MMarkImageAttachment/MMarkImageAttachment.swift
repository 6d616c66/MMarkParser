import UIKit
// MARK: - MMarkImageAttachment

@available(iOS 15.0, *)
public final class MMarkImageAttachment: MMarkBaseAttachment {

    var model: MMarkImageModel {
        guard let model = contentModel as? MMarkImageModel else {
            fatalError("MMarkImageAttachment contentModel is not MMarkImageModel")
        }
        return model
    }

    public var url: String { model.url }
    public var alt: String { model.alt }

    private var _cachedBoundsSize: CGSize?

    public override func attachmentBounds(for textContainer: NSTextContainer?, proposedLineFragment lineFrag: CGRect, glyphPosition position: CGPoint, characterIndex charIndex: Int) -> CGRect {
        if let cached = _cachedBoundsSize {
            return CGRect(origin: .zero, size: cached)
        }
        let imgWidth = max(44, min(model.size.width, lineFrag.width))
        let imgHeight = model.size.height * (imgWidth / max(model.size.width, 1))
        let size = CGSize(width: imgWidth, height: imgHeight)
        _cachedBoundsSize = size
        return CGRect(origin: .zero, size: size)
    }
}
