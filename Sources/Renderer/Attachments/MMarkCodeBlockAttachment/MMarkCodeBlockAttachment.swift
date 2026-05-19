import UIKit
import UniformTypeIdentifiers

// MARK: - MMarkCodeBlockAttachment

@available(iOS 15.0, *)
public final class MMarkCodeBlockAttachment: NSTextAttachment {

    public static let codeBlockFileType = UTType.codeBlockType.identifier

    public let model: MMarkCodeBlockModel

    public var language: String? { model.language }
    public var code: String { model.code }

    public override init(data contentData: Data?, ofType uti: String?) {
        fatalError("use init(model:) instead")
    }

    public init(model: MMarkCodeBlockModel) {
        self.model = model
        super.init(data: nil, ofType: Self.codeBlockFileType)
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