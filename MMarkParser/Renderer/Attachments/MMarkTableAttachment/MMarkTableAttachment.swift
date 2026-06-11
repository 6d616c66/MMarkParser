import UIKit
// MARK: - MMarkTableAttachment

@available(iOS 15.0, *)
public final class MMarkTableAttachment: MMarkBaseAttachment {

    var model: MMarkTableModel { model(as: MMarkTableModel.self) }

    public var headerCells: [NSAttributedString] { model.headerCells }
    public var dataRows: [[NSAttributedString]] { model.dataRows }
    public var alignments: [NSTextAlignment] { model.alignments }
}
