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

    /// 是否为渲染失败的错误状态
    public let isError: Bool

    public init(size: CGSize, image: UIImage, source: String, diagramType: DiagramType, renderedTheme: DiagramTheme, imageWidth: CGFloat, imageHeight: CGFloat, isError: Bool = false) {
        self.image = image
        self.source = source
        self.diagramType = diagramType
        self.renderedTheme = renderedTheme
        self.imageWidth = imageWidth
        self.imageHeight = imageHeight
        self.isError = isError
        super.init(size: size)
    }

    /// 计算颜色的感知亮度 (0~1)，非 RGB 色彩空间会先转换
    private static func luminance(of color: UIColor) -> CGFloat {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        // 先尝试直接 getRed（仅 RGB 色彩空间有效）
        if color.getRed(&r, green: &g, blue: &b, alpha: &a) {
            return 0.299 * r + 0.587 * g + 0.114 * b
        }
        // 非 RGB 色彩空间（如 P3、灰度等），转换后再计算
        let ciColor = CIColor(color: color)
        return 0.299 * ciColor.red + 0.587 * ciColor.green + 0.114 * ciColor.blue
    }

    /// 根据当前 UI 主题和配置决定实际使用的 Mermaid 主题
    public static func resolveTheme(configuration: MMarkStyleConfiguration) -> DiagramTheme {
        guard configuration.mermaidStyle.autoDarkMode else {
            return configuration.mermaidStyle.theme
        }

        let isDark = UITraitCollection.current.userInterfaceStyle == .dark
        let theme = configuration.mermaidStyle.theme
        let lum = luminance(of: theme.background)

        if isDark {
            return lum < 0.5 ? theme : .zincDark
        } else {
            return lum >= 0.5 ? theme : .zincLight
        }
    }

    /// 根据源码首行关键词推断图表类型（避免重复 parse）
    private static func inferDiagramType(source: String) -> DiagramType {
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
        let diagramType = inferDiagramType(source: source)

        do {
            guard let image = try MermaidRenderer.renderImage(source: source, theme: theme) else {
                return nil
            }

            let padding = configuration.mermaidStyle.padding
            let headerHeight = configuration.mermaidStyle.headerHeight

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

    /// 创建渲染失败的错误状态模型
    public static func createError(source: String, width: CGFloat, configuration: MMarkStyleConfiguration = .defaultStyle) -> MMarkMermaidModel {
        let headerHeight = configuration.mermaidStyle.headerHeight
        let errorHeight: CGFloat = 60
        let totalHeight = headerHeight + errorHeight

        // 生成错误占位图
        let errorImage = renderErrorPlaceholder(width: width - configuration.mermaidStyle.padding * 2, height: errorHeight)

        return MMarkMermaidModel(
            size: CGSize(width: width, height: totalHeight),
            image: errorImage,
            source: source,
            diagramType: inferDiagramType(source: source),
            renderedTheme: configuration.mermaidStyle.theme,
            imageWidth: errorImage.size.width,
            imageHeight: errorImage.size.height,
            isError: true
        )
    }

    /// 渲染错误占位图
    private static func renderErrorPlaceholder(width: CGFloat, height: CGFloat) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height))
        return renderer.image { context in
            UIColor.systemRed.withAlphaComponent(0.1).setFill()
            context.fill(CGRect(origin: .zero, size: CGSize(width: width, height: height)))

            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14, weight: .medium),
                .foregroundColor: UIColor.systemRed
            ]
            let text = "Mermaid rendering failed"
            let textSize = (text as NSString).size(withAttributes: attrs)
            let textRect = CGRect(
                x: (width - textSize.width) / 2,
                y: (height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            (text as NSString).draw(in: textRect, withAttributes: attrs)
        }
    }
}