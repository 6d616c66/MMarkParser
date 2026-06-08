// Copyright (c) 2014, 2020 Kiel University and others.
//
// This program and the accompanying materials are made available under the
// terms of the Eclipse Public License 2.0 which is available at
// http://www.eclipse.org/legal/epl-2.0.
//
// SPDX-License-Identifier: EPL-2.0

import Foundation

// MARK: - Adapter Interfaces (non-generic for Swift compatibility)

internal protocol GraphElementAdapter: AnyObject {
    func getProperty<P>(_ prop: IProperty) -> P?
    func hasProperty(_ prop: IProperty) -> Bool
    func getPosition() -> KVector
    func getSize() -> KVector
    func setSize(_ size: KVector)
    func setPosition(_ pos: KVector)
    func getVolatileId() -> Int
    func setVolatileId(_ id: Int)
}

extension GraphElementAdapter {
    /// Non-optional typed getter: force-casts the property value or falls back to a default.
    internal func getProperty<P>(_ prop: IProperty) -> P {
        if let value: P = getProperty(prop) {
            return value
        }
        if let def = prop.defaultValue as? P {
            return def
        }
        do {
            return try _defaultValue(for: P.self)
        } catch {
            fatalError("No default value for property type \(P.self): \(error)")
        }
    }

    /// Convenience computed property delegating to getSize()/setSize(_:).
    internal var size: KVector {
        get { return getSize() }
        set { setSize(newValue) }
    }

    /// Convenience computed property delegating to getPosition()/setPosition(_:).
    internal var position: KVector {
        get { return getPosition() }
        set { setPosition(newValue) }
    }
}

internal protocol GraphAdapter: GraphElementAdapter {
    func getNodes() -> [NodeAdapter]
}

internal protocol NodeAdapter: GraphElementAdapter {
    func getGraph() -> GraphAdapter?
    func getLabels() -> [LabelAdapter]
    func getPorts() -> [PortAdapter]
    func getIncomingEdges() -> [EdgeAdapter]
    func getOutgoingEdges() -> [EdgeAdapter]
    func sortPortList()
    func sortPortList(_ comparator: Any)
    func isCompoundNode() -> Bool
    func getPadding() -> ElkPadding
    func setPadding(_ padding: ElkPadding)
    func getMargin() -> ElkMargin
    func setMargin(_ margin: ElkMargin)
}

internal protocol PortAdapter: GraphElementAdapter {
    func getSide() -> PortSide
    func getLabels() -> [LabelAdapter]
    func getIncomingEdges() -> [EdgeAdapter]
    func getOutgoingEdges() -> [EdgeAdapter]
    func hasCompoundConnections() -> Bool
}

internal protocol LabelAdapter: GraphElementAdapter {
    func getSide() -> LabelSide
    func getText() -> String
}

internal protocol EdgeAdapter: GraphElementAdapter {
    func getLabels() -> [LabelAdapter]
}

// MARK: - ElkGraphAdapters (stub implementation)

internal class ElkGraphAdapters {
    private init() {}

    /// Adapt an ElkNode to a GraphAdapter.
    internal static func adapt(_ node: ElkNode) -> GraphAdapter? {
        // Stub implementation - returns nil. Full implementation would wrap the ElkNode.
        return nil
    }

    /// Adapt a single ElkNode to a NodeAdapter.
    internal static func adaptSingleNode(_ node: ElkNode) -> NodeAdapter? {
        // Stub implementation - returns nil. Full implementation would wrap the ElkNode.
        return nil
    }
}
