import UIKit
@preconcurrency import iosMath

// MARK: - MMarkMathBlockModel

@available(iOS 15.0, *)
public class MMarkMathBlockModel: MMarkBaseModel {
    public let latex: String
    public let latexTextWidth: CGFloat
    public let latexTextHeight: CGFloat

    public init(size: CGSize, latexTextWidth: CGFloat, latexTextHeight: CGFloat, latex: String) {
        self.latexTextWidth = latexTextWidth
        self.latexTextHeight = latexTextHeight
        self.latex = latex
        super.init(size: size)
    }

    /// Factory method: calculate display size from LaTeX content and configuration
    public static func create(latex: String, width: CGFloat, configuration: MMarkStyleConfiguration = .defaultStyle) -> MMarkMathBlockModel {
        let padding: CGFloat = 16
        let labelMargin: CGFloat = 6
        let overflowPadding: CGFloat = 8

        // MTMathUILabel 必须在主线程创建和执行 sizeToFit
        let metrics: (width: CGFloat, height: CGFloat) = DispatchQueue.mainSyncSafe {
            let label = MTMathUILabel()
            label.latex = latex
            label.mode = .display
            if let mathFont = configuration.mathDisplayFont {
                label.font = mathFont
            } else {
                label.fontSize = configuration.mathBlockStyle.font.pointSize
            }
            label.textColor = configuration.mathBlockStyle.textColor
            label.contentInsets = .zero
            label.sizeToFit()
            return (ceil(label.frame.width), ceil(label.frame.height) + overflowPadding)
        }

        let totalWidth = width
        let totalHeight = metrics.height + padding * 2 + labelMargin * 2
        let size = CGSize(width: totalWidth, height: totalHeight)

        return MMarkMathBlockModel(size: size, latexTextWidth: metrics.width, latexTextHeight: metrics.height, latex: latex)
    }
}
