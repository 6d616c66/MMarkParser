import UIKit

// MARK: - MMarkTableViewProvider

@available(iOS 15.0, *)
public final class MMarkTableViewProvider: NSTextAttachmentViewProvider {


    public override func loadView() {
        guard let attachment = self.textAttachment as? MMarkTableAttachment else { return }

        let model = attachment.model
        let view = MMarkTableView(model: model)

        self.view = view
        self.tracksTextAttachmentViewBounds = true

        self.textLayoutManager?.invalidateLayout(for: NSTextRange(location: self.location))
    }
}
