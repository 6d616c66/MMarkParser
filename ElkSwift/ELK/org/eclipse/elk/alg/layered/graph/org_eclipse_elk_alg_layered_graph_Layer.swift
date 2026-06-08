import Foundation

/**
 * A layer in a layered graph.
 */
internal final class Layer: LGraphElement {

    internal var owner: LGraph
    internal var size = KVector()
    internal var nodes = [LNode]()

    internal init(_ graph: LGraph) {
        self.owner = graph
    }

    internal func getSize() -> KVector {
        return size
    }

    internal func getNodes() -> [LNode] {
        return nodes
    }

    internal func getGraph() -> LGraph {
        return owner
    }

    internal func getIndex() -> Int {
        return owner.layers.firstIndex(where: { $0 === self }) ?? -1
    }

    /// Replaces the current nodes list with the given nodes, updating each node's layer reference.
    internal func setNodes(_ nodes: [LNode]) {
        self.nodes = nodes
        for node in nodes {
            node.layer = self
        }
    }

    internal func toString() -> String {
        return "L_\(getIndex())\(nodes)"
    }
}
