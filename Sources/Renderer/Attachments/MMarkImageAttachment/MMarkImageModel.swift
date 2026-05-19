import UIKit

// MARK: - MMarkImageModel

@available(iOS 15.0, *)
public struct MMarkImageModel {
    public let size: CGSize
    public let url: String
    public let alt: String

    public init(size: CGSize, url: String, alt: String) {
        self.size = size
        self.url = url
        self.alt = alt
    }

    /// 工厂方法：根据 url、alt 和 containerWidth 计算 size（4:3 宽高比）并创建模型
    public static func create(url: String, alt: String, width: CGFloat) -> MMarkImageModel {
        let height = width * 3.0 / 4.0
        let size = CGSize(width: width, height: height)
        return MMarkImageModel(size: size, url: url, alt: alt)
    }
}