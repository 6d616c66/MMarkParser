import UIKit
// MARK: - MMarkTableAttachment

@available(iOS 15.0, *)
public final class MMarkTableAttachment: MMarkBaseAttachment {

    var model: MMarkTableModel {
        return contentModel as! MMarkTableModel
    }

    public var headerCells: [NSAttributedString] { model.headerCells }
    public var dataRows: [[NSAttributedString]] { model.dataRows }
    public var alignments: [NSTextAlignment] { model.alignments }


    public override func attachmentBounds(for textContainer: NSTextContainer?, proposedLineFragment lineFrag: CGRect, glyphPosition position: CGPoint, characterIndex charIndex: Int) -> CGRect {
        let width = min(model.size.width, max(lineFrag.width, 44))
        return CGRect(origin: .zero, size: CGSize(width: width, height: model.size.height))
    }
}
