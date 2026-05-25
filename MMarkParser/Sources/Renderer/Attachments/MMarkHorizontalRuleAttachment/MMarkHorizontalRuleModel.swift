import UIKit

// MARK: - MMarkHorizontalRuleModel

@available(iOS 15.0, *)
public class MMarkHorizontalRuleModel: MMarkBaseModel {
    public let ruleConfig: MMarkHorizontalRuleView.MMarkHorizontalRuleConfig

    public init(size: CGSize, ruleConfig: MMarkHorizontalRuleView.MMarkHorizontalRuleConfig = .init()) {
        self.ruleConfig = ruleConfig
        super.init(size: size)
    }

    /// 工厂方法：根据 containerWidth 创建模型
    public static func create(width: CGFloat, configuration: MMarkStyleConfiguration = .defaultStyle) -> MMarkHorizontalRuleModel {
        var config = MMarkHorizontalRuleView.MMarkHorizontalRuleConfig()
        config.ruleColor = configuration.tableStyle.borderColor
        config.ruleHeight = 1.0
        config.verticalPadding = 8.0

        let totalHeight = config.ruleHeight + config.verticalPadding * 2
        let size = CGSize(width: width, height: totalHeight)

        return MMarkHorizontalRuleModel(size: size, ruleConfig: config)
    }
}
