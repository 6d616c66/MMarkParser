import UIKit

public enum MMarkAttachmentType {
    case codeBlock
    case horizontalRule
    case image
    case listMarker
    case mathBlock
    case table
    case mermaid
}

public class MMarkBaseAttachment: NSTextAttachment {

    public static let fileType = "public.data"

    public let attachmentType: MMarkAttachmentType

    public var contentModel: MMarkBaseModel

    public var viewProvider: NSTextAttachmentViewProvider?

    public init(attachmentType: MMarkAttachmentType, content: MMarkBaseModel) {
        self.contentModel = content
        self.attachmentType = attachmentType
        super.init(data: nil, ofType: Self.fileType)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewProvider(for parentView: UIView?, location: any NSTextLocation, textContainer: NSTextContainer?) -> NSTextAttachmentViewProvider? {

        if let provider = self.viewProvider { return provider }

        var viewProvider: NSTextAttachmentViewProvider?
        switch attachmentType {
        case .codeBlock:
            viewProvider = MMarkCodeBlockViewProvider(textAttachment: self, parentView: parentView, textLayoutManager: textContainer?.textLayoutManager, location: location)
        case .horizontalRule:
            viewProvider = MMarkHorizontalRuleViewProvider(textAttachment: self, parentView: parentView, textLayoutManager: textContainer?.textLayoutManager, location: location)
        case .image:
            viewProvider = MMarkImageViewProvider(textAttachment: self, parentView: parentView, textLayoutManager: textContainer?.textLayoutManager, location: location)
        case .listMarker:
            viewProvider = MMarkListMarkerViewProvider(textAttachment: self, parentView: parentView, textLayoutManager: textContainer?.textLayoutManager, location: location)
        case .mathBlock:
            viewProvider = MMarkMathBlockViewProvider(textAttachment: self, parentView: parentView, textLayoutManager: textContainer?.textLayoutManager, location: location)
        case .table:
            viewProvider = MMarkTableViewProvider(textAttachment: self, parentView: parentView, textLayoutManager: textContainer?.textLayoutManager, location: location)
        case .mermaid:
            viewProvider = MMarkMermaidViewProvider(textAttachment: self, parentView: parentView, textLayoutManager: textContainer?.textLayoutManager, location: location)
        }

        if let viewProvider = viewProvider {
            self.viewProvider = viewProvider
            return viewProvider
        }

        return super.viewProvider(for: parentView, location: location, textContainer: textContainer)
    }

    /// Typed access to contentModel. Subclasses call this in a one-liner computed property.
    public func model<T>(as type: T.Type) -> T {
        guard let m = contentModel as? T else {
            fatalError("contentModel type mismatch")
        }
        return m
    }

    /// Default attachment bounds for container-style attachments (code, table, math, mermaid).
    /// Constrains width to line fragment to prevent right-edge corner clipping.
    public override func attachmentBounds(for textContainer: NSTextContainer?, proposedLineFragment lineFrag: CGRect, glyphPosition position: CGPoint, characterIndex charIndex: Int) -> CGRect {
        let width = max(44, min(contentModel.size.width, lineFrag.width) - 1)
        return CGRect(origin: .zero, size: CGSize(width: width, height: contentModel.size.height))
    }
}
