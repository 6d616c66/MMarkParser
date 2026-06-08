// Concrete implementations of the ELK graph model protocols.
// These replace the excluded graph/impl classes with simple,
// array-backed implementations suitable for JSON import/export.

import Foundation

// MARK: - Base Property Holder

internal class ElkPropertyHolder: EObject, IPropertyHolder {
    internal var propertyMap: [String: Any]?

    internal init() {}

    @discardableResult
    internal func setProperty(_ property: IProperty, _ value: Any?) -> Self {
        if let value = value {
            var map = propertyMap ?? [:]
            map[property.id] = value
            propertyMap = map
        } else {
            propertyMap?.removeValue(forKey: property.id)
        }
        return self
    }

    internal func getProperty(_ property: IProperty) -> Any? {
        if let value = propertyMap?[property.id] {
            return value
        }
        return property.defaultValue
    }

    internal func hasProperty(_ property: IProperty) -> Bool {
        return propertyMap?[property.id] != nil
    }

    @discardableResult
    internal func copyProperties(_ holder: IPropertyHolder) -> Self {
        let other = holder.getAllProperties()
        if !other.isEmpty {
            var map = propertyMap ?? [:]
            map.merge(other) { _, new in new }
            propertyMap = map
        }
        return self
    }

    internal func getAllProperties() -> [String: Any] {
        return propertyMap ?? [:]
    }

    // String-key overloads
    @discardableResult
    internal func setProperty(_ key: String, _ value: Any?) -> Self {
        if let value = value {
            var map = propertyMap ?? [:]
            map[key] = value
            propertyMap = map
        } else {
            propertyMap?.removeValue(forKey: key)
        }
        return self
    }

    internal func getProperty(_ key: String) -> Any? {
        return propertyMap?[key]
    }

    internal func hasProperty(_ key: String) -> Bool {
        return propertyMap?[key] != nil
    }
}

// MARK: - Graph Element

internal class ElkGraphElementBase: ElkPropertyHolder, EMapPropertyHolder, ElkGraphElement {
    internal var properties: [String: Any] { return propertyMap ?? [:] }
    internal var labels: [ElkLabel] = []
    internal var identifier: String?
}

// MARK: - Shape

internal class ElkShapeBase: ElkGraphElementBase, ElkShape {
    internal var x: Double = 0
    internal var y: Double = 0
    internal var width: Double = 0
    internal var height: Double = 0

    internal func setDimensions(width: Double, height: Double) {
        self.width = width
        self.height = height
    }

    internal func setLocation(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
}

// MARK: - Connectable Shape

internal class ElkConnectableShapeBase: ElkShapeBase, ElkConnectableShape {
    internal var outgoingEdges: [ElkEdge] = []
    internal var incomingEdges: [ElkEdge] = []
}

// MARK: - Node

internal final class ElkNodeImpl2: ElkConnectableShapeBase, ElkNode {
    internal var ports: [ElkPort] = []
    internal var children: [ElkNode] = []
    internal weak var _parent: AnyObject?
    internal var parent: ElkNode? {
        get { return _parent as? ElkNode }
        set { _parent = newValue as AnyObject? }
    }
    internal var containedEdges: [ElkEdge] = []

    internal func isHierarchical() -> Bool {
        return !children.isEmpty
    }
}

// MARK: - Port

internal final class ElkPortImpl2: ElkConnectableShapeBase, ElkPort {
    internal weak var _parent: AnyObject?
    internal var parent: ElkNode? {
        get { return _parent as? ElkNode }
        set { _parent = newValue as AnyObject? }
    }
}

// MARK: - Label

internal final class ElkLabelImpl2: ElkShapeBase, ElkLabel {
    internal weak var _parent: AnyObject?
    internal var parent: ElkGraphElement? {
        get { return _parent as? ElkGraphElement }
        set { _parent = newValue as AnyObject? }
    }
    internal var text: String = ""
}

// MARK: - Edge

internal final class ElkEdgeImpl2: ElkGraphElementBase, ElkEdge {
    internal weak var _containingNode: AnyObject?
    internal var containingNode: ElkNode? {
        get { return _containingNode as? ElkNode }
        set { _containingNode = newValue as AnyObject? }
    }
    internal var sources: [ElkConnectableShape] = []
    internal var targets: [ElkConnectableShape] = []
    internal var sections: [ElkEdgeSection] = []

    internal func isHyperedge() -> Bool {
        return sources.count > 1 || targets.count > 1
    }

    internal func isHierarchical() -> Bool {
        guard let containingNode = containingNode else { return false }
        for source in sources {
            let sourceNode = (source as? ElkNode) ?? (source as? ElkPort)?.parent
            if sourceNode === containingNode { return true }
            if sourceNode?.parent !== containingNode { return true }
        }
        for target in targets {
            let targetNode = (target as? ElkNode) ?? (target as? ElkPort)?.parent
            if targetNode === containingNode { return true }
            if targetNode?.parent !== containingNode { return true }
        }
        return false
    }

    internal func isSelfloop() -> Bool {
        if sources.isEmpty || targets.isEmpty { return false }
        let sourceNodes = Set(sources.map { ObjectIdentifier(($0 as? ElkNode) ?? (($0 as? ElkPort)?.parent ?? $0) as AnyObject) })
        let targetNodes = Set(targets.map { ObjectIdentifier(($0 as? ElkNode) ?? (($0 as? ElkPort)?.parent ?? $0) as AnyObject) })
        return sourceNodes == targetNodes
    }

    internal func isConnected() -> Bool {
        return !sources.isEmpty && !targets.isEmpty
    }
}

// MARK: - Edge Section

internal final class ElkEdgeSectionImpl2: ElkPropertyHolder, EMapPropertyHolder, ElkEdgeSection {
    internal var properties: [String: Any] { return propertyMap ?? [:] }
    internal var startX: Double = 0
    internal var startY: Double = 0
    internal var endX: Double = 0
    internal var endY: Double = 0
    internal var bendPoints: [ElkBendPoint] = []
    internal weak var _parent: AnyObject?
    internal var parent: ElkEdge? {
        get { return _parent as? ElkEdge }
        set { _parent = newValue as AnyObject? }
    }
    internal var outgoingShape: ElkConnectableShape?
    internal var incomingShape: ElkConnectableShape?
    internal var outgoingSections: [ElkEdgeSection] = []
    internal var incomingSections: [ElkEdgeSection] = []
    internal var identifier: String?

    internal func setStartLocation(x: Double, y: Double) {
        self.startX = x
        self.startY = y
    }

    internal func setEndLocation(x: Double, y: Double) {
        self.endX = x
        self.endY = y
    }
}

// MARK: - Bend Point

internal final class ElkBendPointImpl2: EObject {
    internal var x: Double = 0
    internal var y: Double = 0

    internal init() {}
    internal init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
}

extension ElkBendPointImpl2: ElkBendPoint {
    internal func set(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
}
