import UIKit

// MARK: - MMarkImageViewProvider

@available(iOS 15.0, *)
public final class MMarkImageViewProvider: NSTextAttachmentViewProvider {

    public override init(textAttachment: NSTextAttachment, parentView: UIView?, textLayoutManager: NSTextLayoutManager?, location: NSTextLocation) {
        super.init(textAttachment: textAttachment, parentView: parentView, textLayoutManager: textLayoutManager, location: location)
    }

    public override func loadView() {
        guard let attachment = self.textAttachment as? MMarkImageAttachment else { return }

        let model = attachment.model
        let view = MMarkImageView(size: model.size, url: model.url, alt: model.alt)

        self.view = view
        self.tracksTextAttachmentViewBounds = true
    }
}