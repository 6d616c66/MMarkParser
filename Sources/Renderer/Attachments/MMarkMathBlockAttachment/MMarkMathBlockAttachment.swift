import UIKit
import UniformTypeIdentifiers

// MARK: - MMarkMathBlockAttachment

@available(iOS 15.0, *)
public final class MMarkMathBlockAttachment: NSTextAttachment {

    public static let mathBlockFileType = UTType.mathBlockType.identifier

    public let model: MMarkMathBlockModel

    public var latex: String { model.latex }

    public override init(data contentData: Data?, ofType uti: String?) {
        fatalError("use init(model:) instead")
    }

    public init(model: MMarkMathBlockModel) {
        self.model = model
        super.init(data: nil, ofType: Self.mathBlockFileType)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func attachmentBounds(for textContainer: NSTextContainer?, proposedLineFragment lineFrag: CGRect, glyphPosition position: CGPoint, characterIndex charIndex: Int) -> CGRect {
        // Constrain width to line fragment to prevent right-edge corner clipping
        // from headIndent (blockquote/list) and/or lineFragmentPadding.
        let width = max(44, min(model.size.width, lineFrag.width) - 1)
        return CGRect(origin: .zero, size: CGSize(width: width, height: model.size.height))
    }
}