import UIKit

// MARK: - MMarkMathBlockViewProvider

@available(iOS 15.0, *)
public final class MMarkMathBlockViewProvider: NSTextAttachmentViewProvider {


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
