import UIKit

// MARK: - MMarkHorizontalRuleView

@available(iOS 15.0, *)
public final class MMarkHorizontalRuleView: UIView {
    
    public struct MMarkHorizontalRuleConfig {
        public var ruleColor: UIColor = .systemGray4
        public var ruleHeight: CGFloat = 1.0
        public var verticalPadding: CGFloat = 8.0
        
        public init() {}
    }
    
    public var config: MMarkHorizontalRuleConfig = .init() {
        didSet {
            setNeedsDisplay()
        }
    }
    
    // MARK: - Init
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }
    
    public convenience init(model: MMarkHorizontalRuleModel) {
        self.init(frame: CGRect(origin: .zero, size: model.size))
        self.config = model.ruleConfig
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Drawing
    
    public override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        // 计算水平线的 Y 位置（垂直居中）
        let ruleY = (bounds.height - config.ruleHeight) / 2
        let ruleRect = CGRect(x: 0, y: ruleY, width: bounds.width, height: config.ruleHeight)
        
        context.setFillColor(config.ruleColor.cgColor)
        context.fill(ruleRect)
    }
    
    public override var intrinsicContentSize: CGSize {
        return CGSize(width: frame.width, height: config.ruleHeight + config.verticalPadding * 2)
    }
}
