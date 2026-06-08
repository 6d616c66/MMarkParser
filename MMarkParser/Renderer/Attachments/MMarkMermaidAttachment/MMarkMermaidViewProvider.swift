import UIKit

// MARK: - MMarkMermaidViewProvider

@available(iOS 15.0, *)
public final class MMarkMermaidViewProvider: NSTextAttachmentViewProvider {

    private var mermaidView: MMarkMermaidView?

    public override func loadView() {
        guard let attachment = self.textAttachment as? MMarkMermaidAttachment else { return }

        let model = attachment.model
        let config = attachment.configuration
        let view = MMarkMermaidView(model: model, configuration: config)

        self.mermaidView = view
        self.view = view
        self.tracksTextAttachmentViewBounds = true

        // 监听暗黑模式切换，重新渲染 Mermaid 图表
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleNeedsRerender(_:)),
            name: .MMarkMermaidNeedsRerender,
            object: view
        )
    }

    @objc private func handleNeedsRerender(_ notification: Notification) {
        guard let attachment = self.textAttachment as? MMarkMermaidAttachment else { return }
        let config = attachment.configuration

        guard config.mermaidAutoDarkMode else { return }

        let source = attachment.model.source
        let width = attachment.model.size.width

        // 重新渲染 Mermaid 图表
        if let newModel = MMarkMermaidModel.create(source: source, width: width, configuration: config) {
            DispatchQueue.main.async { [weak self] in
                guard let self = self, let view = self.mermaidView else { return }
                view.updateImage(newModel.image)
            }
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
