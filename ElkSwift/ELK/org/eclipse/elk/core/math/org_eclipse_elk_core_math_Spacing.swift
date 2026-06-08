import Foundation

/**
 * Stores the spacing of an object in `Double` precision.
 */
internal class Spacing {

    /** The spacing from the top. */
    internal var top: Double = 0.0
    /** The spacing from the bottom. */
    internal var bottom: Double = 0.0
    /** The spacing from the left. */
    internal var left: Double = 0.0
    /** The spacing from the right. */
    internal var right: Double = 0.0

    internal init() {}

    internal init(top: Double, right: Double, bottom: Double, left: Double) {
        self.top = top
        self.right = right
        self.bottom = bottom
        self.left = left
    }

    /// Positional init for subclass convenience
    internal init(_ top: Double, _ right: Double, _ bottom: Double, _ left: Double) {
        self.top = top
        self.right = right
        self.bottom = bottom
        self.left = left
    }

    internal func set(_ spacing: Spacing) {
        self.set(spacing.top, spacing.right, spacing.bottom, spacing.left)
    }

    internal func set(_ newTop: Double, _ newRight: Double, _ newBottom: Double, _ newLeft: Double) {
        self.top = newTop
        self.right = newRight
        self.bottom = newBottom
        self.left = newLeft
    }

    internal func getTop() -> Double {
        return top
    }

    internal func setTop(_ top: Double) {
        self.top = top
    }

    internal func getRight() -> Double {
        return right
    }

    internal func setRight(_ right: Double) {
        self.right = right
    }

    internal func getBottom() -> Double {
        return bottom
    }

    internal func setBottom(_ bottom: Double) {
        self.bottom = bottom
    }

    internal func getLeft() -> Double {
        return left
    }

    internal func setLeft(_ left: Double) {
        self.left = left
    }

    internal func setLeftRight(_ val: Double) {
        self.left = val
        self.right = val
    }

    internal func setTopBottom(_ val: Double) {
        self.top = val
        self.bottom = val
    }

    internal func getHorizontal() -> Double {
        return self.left + self.right
    }

    /// Computed property alias for getHorizontal().
    internal var horizontal: Double {
        return self.left + self.right
    }

    internal func getVertical() -> Double {
        return self.top + self.bottom
    }

    /// Computed property alias for getVertical().
    internal var vertical: Double {
        return self.top + self.bottom
    }

    @discardableResult
    internal func copy(_ other: Spacing) -> Self {
        self.left = other.left
        self.right = other.right
        self.top = other.top
        self.bottom = other.bottom
        return self
    }

    @discardableResult
    internal func add(_ other: Spacing) -> Self {
        self.left += other.left
        self.right += other.right
        self.top += other.top
        self.bottom += other.bottom
        return self
    }

    internal func equals(_ other: Spacing) -> Bool {
        return self.top == other.top && self.bottom == other.bottom && self.left == other.left && self.right == other.right
    }

    internal func toString() -> String {
        return "[top=\(top),left=\(left),bottom=\(bottom),right=\(right)]"
    }
}
