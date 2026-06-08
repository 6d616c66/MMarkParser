import Foundation

/**
 * Abstract superclass for the layers, nodes, ports, and edges of a layered graph.
 */
internal class LGraphElement: MapPropertyHolder, Hashable {

    internal static func == (lhs: LGraphElement, rhs: LGraphElement) -> Bool { lhs === rhs }
    internal func hash(into hasher: inout Hasher) { hasher.combine(ObjectIdentifier(self)) }

    /** Identifier value, may be arbitrarily used by algorithms. */
    internal var id: Int = 0

    /**
     * Returns a string that is useful to identify the element while debugging.
     */
    internal func getDesignation() -> String? {
        return nil
    }
}
