import UIKit

// MARK: - MMarkMathBlockViewProvider

@available(iOS 15.0, *)
public final class MMarkMathBlockViewProvider: NSTextAttachmentViewProvider {

    public override init(textAttachment: NSTextAttachment, parentView: UIView?, textLayoutManager: NSTextLayoutManager?, location: NSTextLocation) {
        super.init(textAttachment: textAttachment, parentView: parentView, textLayoutManager: textLayoutManager, location: location)
    }

    public override func loadView() {
        guard let attachment = self.textAttachment as? MMarkMathBlockAttachment else {
            print("[MMarkMathBlockViewProvider] Attachment is not MMarkMathBlockAttachment")
            return
        }

        let model = attachment.model
        print("[MMarkMathBlockViewProvider] Creating view for model size: \(model.size), latex: \(model.latex.prefix(40))")
        let view = MMarkMathBlockView(model: model)

        self.view = view
        self.tracksTextAttachmentViewBounds = true
    }
}
