import Foundation

/**
 * A layered graph has a set of layers that contain the nodes, as well as a
 * list of nodes that are not yet assigned to a layer.
 */
internal final class LGraph: LGraphElement {

    internal var size = KVector()
    internal var padding = LPadding()
    internal var offset = KVector()
    internal var layerlessNodes = [LNode]()
    internal var layers = [Layer]()
    internal var parentNode: LNode?

    internal func getSize() -> KVector {
        return size
    }

    internal func getActualSize() -> KVector {
        return KVector(
            size.x + padding.left + padding.right,
            size.y + padding.top + padding.bottom
        )
    }

    internal func getPadding() -> LPadding {
        return padding
    }

    internal func getOffset() -> KVector {
        return offset
    }

    internal func getLayerlessNodes() -> [LNode] {
        return layerlessNodes
    }

    internal func getLayers() -> [Layer] {
        return layers
    }

    internal func getParentNode() -> LNode? {
        return parentNode
    }

    internal func setParentNode(_ parentNode: LNode?) {
        self.parentNode = parentNode
    }

    /// Creates a new Layer, appends it to the layers list, and sets its graph reference.
    @discardableResult
    internal func addLayer() -> Layer {
        let layer = Layer(self)
        layers.append(layer)
        return layer
    }

    /// Removes the given layer from this graph's layers list.
    internal func removeLayer(_ layer: Layer) {
        layers.removeAll { $0 === layer }
    }

    /// Removes the given node from the layerless nodes list.
    internal func removeLayerlessNode(_ node: LNode) {
        layerlessNodes.removeAll { $0 === node }
    }

    internal func toNodeArray() -> [[LNode]] {
        return layers.map { $0.getNodes() }
    }

    internal func toString() -> String {
        if layers.isEmpty {
            return "G-unlayered\(layerlessNodes)"
        } else if layerlessNodes.isEmpty {
            return "G-layered\(layers)"
        }
        return "G[layerless\(layerlessNodes), layers\(layers)]"
    }
}

// Java's LGraph implements Iterable<Layer>, so support for-in over layers.
extension LGraph: Sequence {
    internal typealias Element = Layer
    internal func makeIterator() -> IndexingIterator<[Layer]> {
        return layers.makeIterator()
    }
}
