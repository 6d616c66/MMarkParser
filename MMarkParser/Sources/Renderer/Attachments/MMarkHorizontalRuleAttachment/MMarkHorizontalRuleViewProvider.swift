import UIKit

// MARK: - MMarkHorizontalRuleViewProvider

@available(iOS 15.0, *)
public final class MMarkHorizontalRuleViewProvider: NSTextAttachmentViewProvider {

    public override init(textAttachment: NSTextAttachment, parentView: UIView?, textLayoutManager: NSTextLayoutManager?, location: NSTextLocation) {
        super.init(textAttachment: textAttachment, parentView: parentView, textLayoutManager: textLayoutManager, location: location)
    }

    public override func loadView() {
        guard let attachment = self.textAttachment as? MMarkHorizontalRuleAttachment else { return }

        let model = attachment.model
        let view = MMarkHorizontalRuleView(model: model)

        self.view = view
        self.tracksTextAttachmentViewBounds = true

        self.textLayoutManager?.invalidateLayout(for: NSTextRange(location: self.location))
    }
}
