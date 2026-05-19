import UIKit
import UniformTypeIdentifiers

// MARK: - MMarkTableAttachment

@available(iOS 15.0, *)
public final class MMarkTableAttachment: NSTextAttachment {

    public static let tableFileType = UTType.tableBlockType.identifier

    public let model: MMarkTableModel

    public var headerCells: [NSAttributedString] { model.headerCells }
    public var dataRows: [[NSAttributedString]] { model.dataRows }
    public var alignments: [NSTextAlignment] { model.alignments }

    public override init(data contentData: Data?, ofType uti: String?) {
        fatalError("use init(model:) instead")
    }

    public init(model: MMarkTableModel) {
        self.model = model
        super.init(data: nil, ofType: Self.tableFileType)
        self.allowsTextAttachmentView = true

        let size = CGSize(width: 1, height: 1)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let transparentImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        self.image = transparentImage
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func attachmentBounds(for textContainer: NSTextContainer?, proposedLineFragment lineFrag: CGRect, glyphPosition position: CGPoint, characterIndex charIndex: Int) -> CGRect {
        let width = min(model.size.width, max(lineFrag.width, 44))
        return CGRect(origin: .zero, size: CGSize(width: width, height: model.size.height))
    }

    public override func viewProvider(for parentView: UIView?, location: NSTextLocation, textContainer: NSTextContainer?) -> NSTextAttachmentViewProvider? {
        return MMarkTableViewProvider(textAttachment: self, parentView: parentView, textLayoutManager: textContainer?.textLayoutManager, location: location)
    }
}