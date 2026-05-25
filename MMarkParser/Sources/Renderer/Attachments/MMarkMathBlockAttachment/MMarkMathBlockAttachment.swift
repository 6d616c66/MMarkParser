import UIKit
// MARK: - MMarkMathBlockAttachment

@available(iOS 15.0, *)
public final class MMarkMathBlockAttachment: MMarkBaseAttachment {

    public var model: MMarkMathBlockModel {
        return contentModel as! MMarkMathBlockModel
    }

    public var latex: String { model.latex }

    public override func attachmentBounds(for textContainer: NSTextContainer?, proposedLineFragment lineFrag: CGRect, glyphPosition position: CGPoint, characterIndex charIndex: Int) -> CGRect {
        // Constrain width to line fragment to prevent right-edge corner clipping
        // from headIndent (blockquote/list) and/or lineFragmentPadding.
        let width = max(44, min(model.size.width, lineFrag.width) - 1)
        return CGRect(origin: .zero, size: CGSize(width: width, height: model.size.height))
    }
}
