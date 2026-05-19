import UIKit
import UniformTypeIdentifiers

// MARK: - MMarkImageAttachment

@available(iOS 15.0, *)
public final class MMarkImageAttachment: NSTextAttachment {

    public static let imageFileType = UTType.imageBlockType.identifier

    public let model: MMarkImageModel

    public var url: String { model.url }
    public var alt: String { model.alt }

    public override init(data contentData: Data?, ofType uti: String?) {
        fatalError("use init(model:) instead")
    }

    public init(model: MMarkImageModel) {
        self.model = model
        super.init(data: nil, ofType: Self.imageFileType)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func attachmentBounds(for textContainer: NSTextContainer?, proposedLineFragment lineFrag: CGRect, glyphPosition position: CGPoint, characterIndex charIndex: Int) -> CGRect {
        return CGRect(origin: .zero, size: model.size)
    }
}