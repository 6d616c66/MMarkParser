import UIKit
import iosMath

// MARK: - MMarkMathBlockModel

@available(iOS 15.0, *)
public struct MMarkMathBlockModel {
    public let size: CGSize
    public let latex: String
    public let latexTextWidth: CGFloat
    public let latexTextHeight: CGFloat

    public init(size: CGSize, latexTextWidth: CGFloat, latexTextHeight: CGFloat, latex: String) {
        self.size = size
        self.latexTextWidth = latexTextWidth
        self.latexTextHeight = latexTextHeight
        self.latex = latex
    }

    /// Factory method: calculate display size from LaTeX content and configuration
    public static func create(latex: String, width: CGFloat, configuration: MMarkStyleConfiguration = .defaultStyle) -> MMarkMathBlockModel {
        let padding: CGFloat = 16
        let labelMargin: CGFloat = 6
        let overflowPadding: CGFloat = 8

        // Use MTMathUILabel for accurate LaTeX rendering size calculation
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

        let textWidth = ceil(label.frame.width)
        let textHeight = ceil(label.frame.height) + overflowPadding

        let totalWidth = width
        let totalHeight = textHeight + padding * 2 + labelMargin * 2
        let size = CGSize(width: totalWidth, height: totalHeight)

        return MMarkMathBlockModel(size: size, latexTextWidth: textWidth, latexTextHeight: textHeight, latex: latex)
    }
}
