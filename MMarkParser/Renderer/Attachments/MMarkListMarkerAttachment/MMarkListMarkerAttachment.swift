import UIKit
// MARK: - MMarkListMarkerAttachment

@available(iOS 15.0, *)
public final class MMarkListMarkerAttachment: MMarkBaseAttachment {

    var model: MMarkListMarkerModel {
        guard let model = contentModel as? MMarkListMarkerModel else {
            fatalError("MMarkListMarkerAttachment contentModel is not MMarkListMarkerModel")
        }
        return model
    }

    public override func attachmentBounds(for textContainer: NSTextContainer?, proposedLineFragment lineFrag: CGRect, glyphPosition position: CGPoint, characterIndex charIndex: Int) -> CGRect {
        return model.bounds
    }
}
