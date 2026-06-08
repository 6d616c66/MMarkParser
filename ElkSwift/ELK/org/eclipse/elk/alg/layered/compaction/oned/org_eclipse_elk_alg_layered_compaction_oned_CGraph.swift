import Foundation

/**
 * Internal representation of a constraint graph.
 * The `LGraphToCGraphTransformer` returns a `CGraph` to be compacted by the
 * `OneDimensionalCompactor`.
 */
internal final class CGraph {
    // Variables are internal for convenience reasons since this class is used internally only.
    /// the list of `CNode`s modeling the constraints in this graph.
    internal var cNodes: [CNode] = []
    /// groups of elements that are supposed to stay in the configuration they are.
    internal var cGroups: [CGroup] = []
    /// the directions that are supported for compaction.
    internal let supportedDirections: Set<Direction>
    
    /**
     * Constructor sets the supported directions.
     *
     * - Parameter supportedDirections: the directions that are supported for compaction
     */
    internal init(_ supportedDirections: Set<Direction>) {
        self.supportedDirections = supportedDirections
    }
    
    /**
     * Checks whether the `CGraph` supports compaction in the direction specified by the parameter.
     *
     * - Parameter direction: the direction to check
     * - Returns: `true` if compaction is supported, `false` otherwise
     */
    internal func supports(_ direction: Direction) -> Bool {
        return supportedDirections.contains(direction)
    }
}
