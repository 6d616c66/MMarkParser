import UIKit
// MARK: - MMarkMathBlockAttachment

@available(iOS 15.0, *)
public final class MMarkMathBlockAttachment: MMarkBaseAttachment {

    public var model: MMarkMathBlockModel { model(as: MMarkMathBlockModel.self) }

    public var latex: String { model.latex }
}
