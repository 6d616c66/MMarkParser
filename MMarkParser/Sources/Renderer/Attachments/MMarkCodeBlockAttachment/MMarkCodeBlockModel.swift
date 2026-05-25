import UIKit

// MARK: - MMarkCodeBlockModel

@available(iOS 15.0, *)
public class MMarkCodeBlockModel: MMarkBaseModel {
    public let codeTextWidth: CGFloat
    public let codeTextHeight: CGFloat
    public let highlightedCode: NSAttributedString
    public let language: String?
    public let code: String

    public init(size: CGSize, codeTextWidth: CGFloat, codeTextHeight: CGFloat, highlightedCode: NSAttributedString, language: String?, code: String) {
        self.codeTextWidth = codeTextWidth
        self.codeTextHeight = codeTextHeight
        self.highlightedCode = highlightedCode
        self.language = language
        self.code = code
        super.init(size: size)
    }

    /// 工厂方法：根据 language、code、containerWidth 计算 size 并创建模型
    public static func create(language: String?, code: String, width: CGFloat, configuration: MMarkStyleConfiguration = .defaultStyle) -> MMarkCodeBlockModel {
        var config = MMarkCodeBlockView.MMarkCodeBlockConfig()
        config.headerBackgroundColor = configuration.codeBlockHeaderBackgroundColor
        config.bodyBackgroundColor = configuration.codeBlockBodyBackgroundColor
        config.cornerRadius = configuration.codeBlockCornerRadius
        config.headerHeight = configuration.codeBlockHeaderHeight
        config.padding = configuration.codeBlockPadding
        let highlightedCode = MMarkCodeBlockView.highlightedCode(language: language, code: code, configuration: configuration)

        // 计算代码文本的自然尺寸（不换行，支持水平滚动）
        let naturalCodeSize = highlightedCode.boundingRect(
            with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )
        let codeTextWidth = ceil(naturalCodeSize.width)
        let codeTextHeight = ceil(naturalCodeSize.height)

        let totalHeight = ceil(config.headerHeight) + codeTextHeight + config.padding * 2
        let size = CGSize(width: width, height: totalHeight)
        return MMarkCodeBlockModel(size: size, codeTextWidth: codeTextWidth, codeTextHeight: codeTextHeight, highlightedCode: highlightedCode, language: language, code: code)
    }
}
