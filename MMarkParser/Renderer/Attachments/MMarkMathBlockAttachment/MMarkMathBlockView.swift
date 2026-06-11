import UIKit
@preconcurrency import iosMath

// MARK: - MMarkMathBlockView

@available(iOS 15.0, *)
public final class MMarkMathBlockView: UIView {

    public var latex: String = ""
    public var configuration: MMarkStyleConfiguration = .defaultStyle

    // MARK: - Subviews

    private let latexScrollView = UIScrollView()
    private let latexMathLabel = MTMathUILabel()

    // MARK: - Init

    public override init(frame: CGRect) {
        super.init(frame: frame)
        MMarkFontLoader.ensureFontsRegistered()
        setupViews()
    }

    public convenience init(model: MMarkMathBlockModel, configuration: MMarkStyleConfiguration = .defaultStyle) {
        self.init(frame: CGRect(origin: .zero, size: model.size))
        self.latex = model.latex
        self.configuration = configuration

        // Apply configuration-dependent appearance
        self.backgroundColor = configuration.mathBlockBackgroundColor
        self.layer.cornerRadius = configuration.mathBlockCornerRadius

        // Configure MTMathUILabel with the LaTeX content
        latexMathLabel.latex = model.latex
        latexMathLabel.mode = .display
        if let mathFont = configuration.mathDisplayFont {
            latexMathLabel.font = mathFont
        } else {
            latexMathLabel.fontSize = configuration.mathBlockStyle.font.pointSize
        }
        latexMathLabel.textColor = configuration.mathBlockStyle.textColor
        latexMathLabel.contentInsets = .zero
        latexMathLabel.sizeToFit()
        // MTMathUILabel.sizeToFit() underestimates height for tall expressions (matrices,
        // fractions, etc.) because its drawRect CGContext clips to bounds.
        // Expand label frame to prevent clipping of rendered glyphs.
        let labelMargin: CGFloat = 6
        let overflowPadding: CGFloat = 8
        latexMathLabel.frame.origin.y = labelMargin - overflowPadding / 2
        latexMathLabel.frame.size.height += overflowPadding
        latexScrollView.contentSize = CGSize(width: latexMathLabel.frame.width, height: latexMathLabel.frame.height + labelMargin * 2)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupViews() {
        backgroundColor = configuration.mathBlockBackgroundColor
        layer.cornerRadius = configuration.mathBlockCornerRadius
        clipsToBounds = true
        translatesAutoresizingMaskIntoConstraints = false

        // LaTeX scroll view
        latexScrollView.showsHorizontalScrollIndicator = true
        latexScrollView.showsVerticalScrollIndicator = false
        latexScrollView.backgroundColor = .clear
        latexScrollView.translatesAutoresizingMaskIntoConstraints = false
        latexScrollView.layer.masksToBounds = false
        latexScrollView.clipsToBounds = false
        addSubview(latexScrollView)

        // MTMathUILabel for rendered LaTeX (frame-based layout)
        latexMathLabel.backgroundColor = .clear
        latexScrollView.addSubview(latexMathLabel)

        setupConstraints()
    }

    private func setupConstraints() {
        let padding: CGFloat = 16

        NSLayoutConstraint.activate([
            // latexScrollView
            latexScrollView.topAnchor.constraint(equalTo: topAnchor, constant: padding),
            latexScrollView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
            latexScrollView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding),
            latexScrollView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -padding)
        ])
    }

    // MARK: - Layout

    public override var intrinsicContentSize: CGSize {
        return CGSize(width: frame.width, height: frame.height)
    }
}
