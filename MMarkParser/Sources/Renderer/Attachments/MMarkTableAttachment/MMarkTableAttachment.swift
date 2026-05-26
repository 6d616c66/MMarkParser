import UIKit
// MARK: - MMarkTableAttachment

@available(iOS 15.0, *)
public final class MMarkTableAttachment: MMarkBaseAttachment {

    var model: MMarkTableModel {
        guard let model = contentModel as? MMarkTableModel else {
            fatalError("MMarkTableAttachment contentModel is not MMarkTableModel")
        }
        return model
    }

    public var headerCells: [NSAttributedString] { model.headerCells }
    public var dataRows: [[NSAttributedString]] { model.dataRows }
    public var alignments: [NSTextAlignment] { model.alignments }

    public override func attachmentBounds(for textContainer: NSTextContainer?, proposedLineFragment lineFrag: CGRect, glyphPosition position: CGPoint, characterIndex charIndex: Int) -> CGRect {
        let width = max(44, min(model.size.width, lineFrag.width) - 1)
        return CGRect(origin: .zero, size: CGSize(width: width, height: model.size.height))
    }
}
