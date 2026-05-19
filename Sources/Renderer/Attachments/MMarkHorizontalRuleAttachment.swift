import UIKit

/// NSTextAttachment that renders a horizontal rule (thematic break)
@available(iOS 15.0, *)
public final class MMarkHorizontalRuleAttachment: NSTextAttachment {

    public var ruleHeight: CGFloat = 1
    public var ruleColor: UIColor = .systemGray4

    public override func image(forBounds imageBounds: CGRect, textContainer: NSTextContainer?, characterIndex charIndex: Int) -> UIImage? {
        let width = imageBounds.width
        guard width > 0 else { return nil }

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: ruleHeight))
        return renderer.image { ctx in
            ctx.cgContext.setFillColor(ruleColor.cgColor)
            ctx.fill(CGRect(x: 0, y: 0, width: width, height: ruleHeight))
        }
    }

    public override func attachmentBounds(for textContainer: NSTextContainer?, proposedLineFragment lineFrag: CGRect, glyphPosition position: CGPoint, characterIndex charIndex: Int) -> CGRect {
        let width = lineFrag.width
        return CGRect(x: 0, y: 8, width: width, height: ruleHeight)
    }
}