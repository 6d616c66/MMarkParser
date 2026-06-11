import UIKit

// MARK: - MMarkCodeBlockViewProvider

@available(iOS 15.0, *)
public final class MMarkCodeBlockViewProvider: NSTextAttachmentViewProvider {


    public override func loadView() {
        guard let attachment = self.textAttachment as? MMarkCodeBlockAttachment else { return }

        let model = attachment.model
        let view = MMarkCodeBlockView(model: model)

        self.view = view
        self.tracksTextAttachmentViewBounds = true
    }
}
