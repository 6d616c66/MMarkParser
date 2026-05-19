import Foundation

extension NSAttributedString {
    /// 使用 MMarkParser 解析 Markdown
    /// - Parameters:
    ///   - markdown: Markdown 文本
    ///   - configuration: 样式配置，默认为 GFM 默认样式
    /// - Returns: 解析后的 NSAttributedString
    @available(iOS 15.0, *)
    public static func fromMarkdown(
        _ markdown: String,
        configuration: MMarkStyleConfiguration = .defaultStyle
    ) -> NSAttributedString {
        return MMarkParser.parse(markdown: markdown, configuration: configuration)
    }
}

extension NSMutableAttributedString {
    /// 追加解析后的 Markdown
    /// - Parameters:
    ///   - markdown: Markdown 文本
    ///   - configuration: 样式配置
    @available(iOS 15.0, *)
    public func appendMarkdown(
        _ markdown: String,
        configuration: MMarkStyleConfiguration = .defaultStyle
    ) {
        let attributedString = NSAttributedString.fromMarkdown(markdown, configuration: configuration)
        self.append(attributedString)
    }
}
