import UIKit

// MARK: - MMarkCodeBlockAttachment

@available(iOS 15.0, *)
public final class MMarkCodeBlockAttachment: MMarkBaseAttachment {

    public var model: MMarkCodeBlockModel { model(as: MMarkCodeBlockModel.self) }
}
