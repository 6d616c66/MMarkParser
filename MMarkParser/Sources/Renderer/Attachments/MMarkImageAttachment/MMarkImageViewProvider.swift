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
        let view = MMarkImageView(size: model.realSize ?? model.size, url: model.url, alt: model.alt, placeholderColor: model.placeholderColor)

        // 图片加载完成后，通知 TextKit 2 重新布局 attachment 所在范围
        view.onImageLoaded = { [weak self] in
//            guard let self = self,
//                  let textLayoutManager = self.textLayoutManager else { return }
//            let location = self.location
//            // 扩展 range 覆盖 attachment 字符，确保 TextKit 2 重新计算位置
//            let endLocation = textLayoutManager.location(location, offsetBy: 1) ?? location
//            if let invalidateRange = NSTextRange(location: location, end: endLocation) {
//                textLayoutManager.invalidateLayout(for: invalidateRange)
//            }
        }
        self.view = view
        self.tracksTextAttachmentViewBounds = true
    }
}
