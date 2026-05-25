import UIKit

// MARK: - MMarkMathBlockViewProvider

@available(iOS 15.0, *)
public final class MMarkMathBlockViewProvider: NSTextAttachmentViewProvider {

    public override init(textAttachment: NSTextAttachment, parentView: UIView?, textLayoutManager: NSTextLayoutManager?, location: NSTextLocation) {
        super.init(textAttachment: textAttachment, parentView: parentView, textLayoutManager: textLayoutManager, location: location)
    }

    public override func loadView() {
        guard let attachment = self.textAttachment as? MMarkMathBlockAttachment else {
            return
        }

        let model = attachment.model
        let view = MMarkMathBlockView(model: model)

        self.view = view
        self.tracksTextAttachmentViewBounds = true
    }
}
