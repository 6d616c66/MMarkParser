import UIKit

// MARK: - MMarkListMarkerViewProvider

@available(iOS 15.0, *)
public final class MMarkListMarkerViewProvider: NSTextAttachmentViewProvider {

    public override init(textAttachment: NSTextAttachment, parentView: UIView?, textLayoutManager: NSTextLayoutManager?, location: NSTextLocation) {
        super.init(textAttachment: textAttachment, parentView: parentView, textLayoutManager: textLayoutManager, location: location)
    }

    public override func loadView() {
        guard let attachment = self.textAttachment as? MMarkListMarkerAttachment else { return }

        self.view = MMarkListMarkerView(model: attachment.model)
        self.tracksTextAttachmentViewBounds = true
    }
}
