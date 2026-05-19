import Foundation
import UIKit

/// MMarkParser - iOS Markdown 解析渲染库
public enum MMarkParser {
    /// 默认样式配置
    public static var defaultStyle: MMarkStyleConfiguration {
        return .defaultStyle
    }

    /// 解析 Markdown 文本为 NSAttributedString
    /// - Parameters:
    ///   - markdown: Markdown 文本
    ///   - configuration: 样式配置，默认为 GFM 默认样式
    /// - Returns: 解析后的 NSAttributedString
    @available(iOS 15.0, *)
    public static func parse(
        markdown: String,
        configuration: MMarkStyleConfiguration = .defaultStyle
    ) -> NSAttributedString {
        let parser = CMarkParser()
        do {
            return try parser.parse(markdown, configuration: configuration)
        } catch {
            // 如果解析失败，返回普通文本
            return NSAttributedString(string: markdown)
        }
    }

    /// 创建 TextKit2 渲染器
    /// - Parameter configuration: 样式配置
    /// - Returns: MMarkTextKit2Renderer 实例
    @available(iOS 15.0, *)
    public static func createRenderer(
        configuration: MMarkStyleConfiguration = .defaultStyle
    ) -> MMarkTextKit2Renderer {
        return MMarkTextKit2Renderer(configuration: configuration)
    }
}

// MARK: - 便捷扩展

@available(iOS 15.0, *)
public extension String {
    /// 将当前字符串作为 Markdown 解析为 NSAttributedString
    func parseMarkdown(
        configuration: MMarkStyleConfiguration = .defaultStyle
    ) -> NSAttributedString {
        return MMarkParser.parse(markdown: self, configuration: configuration)
    }
}
