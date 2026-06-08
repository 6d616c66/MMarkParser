import UIKit

// MARK: - MMarkMermaidAttachment

@available(iOS 15.0, *)
public final class MMarkMermaidAttachment: MMarkBaseAttachment {

    public var model: MMarkMermaidModel {
        guard let model = contentModel as? MMarkMermaidModel else {
            fatalError("MMarkMermaidAttachment contentModel is not MMarkMermaidModel")
        }
        return model
    }

    /// 保存渲染时使用的配置，供 ViewProvider 使用
    public let configuration: MMarkStyleConfiguration

    public init(attachmentType: MMarkAttachmentType, content: MMarkMermaidModel, configuration: MMarkStyleConfiguration) {
        self.configuration = configuration
        super.init(attachmentType: attachmentType, content: content)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func attachmentBounds(for textContainer: NSTextContainer?, proposedLineFragment lineFrag: CGRect, glyphPosition position: CGPoint, characterIndex charIndex: Int) -> CGRect {
        let width = max(44, min(model.size.width, lineFrag.width) - 1)
        let height = model.size.height
        return CGRect(origin: .zero, size: CGSize(width: width, height: height))
    }
}
