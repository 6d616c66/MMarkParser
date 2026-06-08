import UIKit
import BeautifulMermaidSwift

// MARK: - MMarkMermaidModel

@available(iOS 15.0, *)
public class MMarkMermaidModel: MMarkBaseModel {
    public let image: UIImage
    public let source: String
    /// 图表类型（用于 header 标签显示）
    public let diagramType: DiagramType

    /// 渲染所使用的主题（用于暗黑模式判断）
    public let renderedTheme: DiagramTheme

    /// 图片自然宽度（point），供 ScrollView 内容布局使用
    public let imageWidth: CGFloat
    /// 图片自然高度（point），供 ScrollView 内容布局使用
    public let imageHeight: CGFloat

    public init(size: CGSize, image: UIImage, source: String, diagramType: DiagramType, renderedTheme: DiagramTheme, imageWidth: CGFloat, imageHeight: CGFloat) {
        self.image = image
        self.source = source
        self.diagramType = diagramType
        self.renderedTheme = renderedTheme
        self.imageWidth = imageWidth
        self.imageHeight = imageHeight
        super.init(size: size)
    }

    /// 根据当前 UI 主题和配置决定实际使用的 Mermaid 主题
    public static func resolveTheme(configuration: MMarkStyleConfiguration) -> DiagramTheme {
        guard configuration.mermaidAutoDarkMode else {
            return configuration.mermaidTheme
        }

        let isDark = UITraitCollection.current.userInterfaceStyle == .dark
        if isDark {
            let theme = configuration.mermaidTheme
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            #if canImport(UIKit)
            theme.background.getRed(&r, green: &g, blue: &b, alpha: &a)
            #endif
            let luminance = 0.299 * r + 0.587 * g + 0.114 * b
            if luminance < 0.5 {
                return theme
            }
            return .zincDark
        } else {
            let theme = configuration.mermaidTheme
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            #if canImport(UIKit)
            theme.background.getRed(&r, green: &g, blue: &b, alpha: &a)
            #endif
            let luminance = 0.299 * r + 0.587 * g + 0.114 * b
            if luminance >= 0.5 {
                return theme
            }
            return .zincLight
        }
    }

    /// 尝试解析图表类型，失败时回退为 flowchart
    private static func detectDiagramType(source: String) -> DiagramType {
        do {
            let graph = try MermaidRenderer.parse(source)
            return graph.type
        } catch {
            let firstLine = source
                .components(separatedBy: .newlines)
                .first?
                .lowercased()
                .trimmingCharacters(in: .whitespaces) ?? ""
            if firstLine.hasPrefix("sequencediagram") { return .sequenceDiagram }
            if firstLine.hasPrefix("classdiagram") { return .classDiagram }
            if firstLine.hasPrefix("erdiagram") { return .erDiagram }
            if firstLine.hasPrefix("statediagram") { return .stateDiagram }
            if firstLine.hasPrefix("xychart") { return .xyChart }
            return .flowchart
        }
    }

    /// 图表类型的用户友好显示名称
    public var diagramTypeName: String {
        switch diagramType {
        case .flowchart: return "Flowchart"
        case .stateDiagram: return "State Diagram"
        case .sequenceDiagram: return "Sequence Diagram"
        case .classDiagram: return "Class Diagram"
        case .erDiagram: return "ER Diagram"
        case .xyChart: return "XY Chart"
        }
    }

    public static func create(source: String, width: CGFloat, configuration: MMarkStyleConfiguration = .defaultStyle) -> MMarkMermaidModel? {
        let theme = resolveTheme(configuration: configuration)
        let diagramType = detectDiagramType(source: source)

        do {
            guard let image = try MermaidRenderer.renderImage(source: source, theme: theme) else {
                return nil
            }

            let padding = configuration.mermaidPadding
            let headerHeight = configuration.mermaidHeaderHeight

            // 图片自然尺寸（point）
            let imageWidth = image.size.width
            let imageHeight = image.size.height

            // 总高度 = header + padding(上) + 图片自然高度 + padding(下)
            // 总宽度 = 容器宽度（ScrollView 会处理超出部分的水平滚动）
            let totalHeight = headerHeight + padding + imageHeight + padding
            let size = CGSize(width: width, height: totalHeight)

            return MMarkMermaidModel(
                size: size,
                image: image,
                source: source,
                diagramType: diagramType,
                renderedTheme: theme,
                imageWidth: imageWidth,
                imageHeight: imageHeight
            )
        } catch {
            print("Failed to render Mermaid: \(error)")
            return nil
        }
    }
}