import UIKit

// MARK: - MMarkListMarkerModel

@available(iOS 15.0, *)
public class MMarkListMarkerModel: MMarkBaseModel {
    public let image: UIImage
    public let bounds: CGRect

    public init(image: UIImage, bounds: CGRect) {
        self.image = image
        self.bounds = bounds
        super.init(size: bounds.size)
    }
}
