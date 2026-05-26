import UIKit
// MARK: - MMarkHorizontalRuleAttachment

/// NSTextAttachment that renders a horizontal rule (thematic break)
@available(iOS 15.0, *)
public final class MMarkHorizontalRuleAttachment: MMarkBaseAttachment {

    var model: MMarkHorizontalRuleModel {
        return (contentModel as? MMarkHorizontalRuleModel) ?? (MMarkHorizontalRuleModel.create(width: UIScreen.main.bounds.width - 32))
    }

    public var ruleHeight: CGFloat { model.ruleConfig.ruleHeight }
    public var ruleColor: UIColor { model.ruleConfig.ruleColor }

    public override init(attachmentType: MMarkAttachmentType, content: MMarkBaseModel) {
        super.init(attachmentType: attachmentType, content: content)
        self.allowsTextAttachmentView = true

        // Create a transparent placeholder image
        let size = CGSize(width: 1, height: 1)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let transparentImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        self.image = transparentImage
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func attachmentBounds(for textContainer: NSTextContainer?, proposedLineFragment lineFrag: CGRect, glyphPosition position: CGPoint, characterIndex charIndex: Int) -> CGRect {
        let width = min(model.size.width, max(lineFrag.width, 44))
        return CGRect(origin: .zero, size: CGSize(width: width, height: model.size.height))
    }
}
