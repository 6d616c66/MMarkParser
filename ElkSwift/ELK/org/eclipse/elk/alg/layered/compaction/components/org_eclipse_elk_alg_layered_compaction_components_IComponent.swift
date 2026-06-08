/**
 * A component represents a set of nodes that are fully connected.
 */
internal protocol IComponent: AnyObject {
    /// The hull rectangles of this component.
    func getHull() -> [ElkRectangle]

    /// The external extensions of this component.
    func getExternalExtensions() -> [Any]

    /// The external extension port sides.
    var externalExtensionSides: Set<PortSide> { get }
}
