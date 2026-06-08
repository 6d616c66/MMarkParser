import Foundation

/**
 * Stores the margins of an element.
 */
internal class ElkMargin: Spacing {

    internal override init() {
        super.init()
    }

    internal init(_ any: Double) {
        super.init(any, any, any, any)
    }

    internal init(_ leftRight: Double, _ topBottom: Double) {
        super.init(topBottom, leftRight, topBottom, leftRight)
    }

    internal override init(_ top: Double, _ right: Double, _ bottom: Double, _ left: Double) {
        super.init(top, right, bottom, left)
    }

    internal init(_ other: ElkMargin) {
        super.init(other.top, other.right, other.bottom, other.left)
    }
}
