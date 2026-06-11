import UIKit

// MARK: - MMarkMermaidAttachment

@available(iOS 15.0, *)
public final class MMarkMermaidAttachment: MMarkBaseAttachment {

    public var model: MMarkMermaidModel { model(as: MMarkMermaidModel.self) }

    /// 保存渲染时使用的配置，供 ViewProvider 使用
    public let configuration: MMarkStyleConfiguration

    public init(attachmentType: MMarkAttachmentType, content: MMarkMermaidModel, configuration: MMarkStyleConfiguration) {
        self.configuration = configuration
        super.init(attachmentType: attachmentType, content: content)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
