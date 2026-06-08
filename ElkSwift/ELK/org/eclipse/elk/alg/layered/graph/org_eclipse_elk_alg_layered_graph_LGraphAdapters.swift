// Copyright (c) 2014, 2019 Kiel University and others.
//
// This program and the accompanying materials are made available under the
// terms of the Eclipse Public License 2.0 which is available at
// http://www.eclipse.org/legal/epl-2.0.
//
// SPDX-License-Identifier: EPL-2.0

import Foundation

/// Provides implementations of the GraphAdapters interfaces for the LGraph.
internal final class LGraphAdapters {

    private init() {}

    internal static func adapt(_ graph: LGraph) -> LGraphAdapter {
        return LGraphAdapter(graph, transparentNorthSouthEdges: false, transparentCommentNodes: false, nodeFilter: { _ in true })
    }

    internal static func adapt(_ graph: LGraph, transparentNorthSouthEdges: Bool) -> LGraphAdapter {
        return LGraphAdapter(graph, transparentNorthSouthEdges: transparentNorthSouthEdges, transparentCommentNodes: false, nodeFilter: { _ in true })
    }

    internal static func adapt(_ graph: LGraph, transparentNorthSouthEdges: Bool, transparentCommentNodes: Bool, nodeFilter: @escaping (LNode) -> Bool) -> LGraphAdapter {
        return LGraphAdapter(graph, transparentNorthSouthEdges: transparentNorthSouthEdges, transparentCommentNodes: transparentCommentNodes, nodeFilter: nodeFilter)
    }

    internal static func adapt(_ node: LNode, transparentNorthSouthEdges: Bool) -> LNodeAdapter {
        return LNodeAdapter(parentGraphAdapter: nil, element: node, transparentNorthSouthEdges: transparentNorthSouthEdges)
    }

    internal static func adapt(_ label: LLabel) -> LLabelAdapter {
        return LLabelAdapter(label)
    }

    // MARK: - LGraphAdapter

    internal class LGraphAdapter: GraphAdapter {
        internal let element: LGraph
        internal var nodeAdapters: [NodeAdapter]?
        internal let transparentNorthSouthEdges: Bool
        internal let transparentCommentNodes: Bool
        internal let nodeFilter: (LNode) -> Bool

        init(_ element: LGraph, transparentNorthSouthEdges: Bool, transparentCommentNodes: Bool, nodeFilter: @escaping (LNode) -> Bool) {
            self.element = element
            self.transparentNorthSouthEdges = transparentNorthSouthEdges
            self.transparentCommentNodes = transparentCommentNodes
            self.nodeFilter = nodeFilter
        }

        internal func getSize() -> KVector { return element.getSize() }
        internal func setSize(_ size: KVector) { element.size = size }
        internal func getPosition() -> KVector { return element.offset }
        internal func setPosition(_ pos: KVector) { element.offset = pos }
        internal func getProperty<P>(_ prop: IProperty) -> P? { return element.getProperty(prop) as? P }
        internal func hasProperty(_ prop: IProperty) -> Bool { return element.hasProperty(prop) }
        internal func getVolatileId() -> Int { return element.id }
        internal func setVolatileId(_ id: Int) { element.id = id }

        internal func getNodes() -> [NodeAdapter] {
            if let cached = nodeAdapters { return cached }
            var computed: [NodeAdapter] = []
            for layer in element.getLayers() {
                for node in layer.getNodes() {
                    if nodeFilter(node) {
                        computed.append(LNodeAdapter(parentGraphAdapter: self, element: node, transparentNorthSouthEdges: transparentNorthSouthEdges))
                    }
                }
            }
            nodeAdapters = computed
            return computed
        }
    }

    // MARK: - LNodeAdapter

    internal class LNodeAdapter: NodeAdapter {
        internal weak var parentGraphAdapter: LGraphAdapter?
        internal let element: LNode
        internal var labelAdapters: [LabelAdapter]?
        internal var portAdapters: [PortAdapter]?
        internal let transparentNorthSouthEdges: Bool

        init(parentGraphAdapter: LGraphAdapter?, element: LNode, transparentNorthSouthEdges: Bool) {
            self.parentGraphAdapter = parentGraphAdapter
            self.element = element
            self.transparentNorthSouthEdges = transparentNorthSouthEdges
        }

        internal func getSize() -> KVector { return element.getSize() }
        internal func setSize(_ size: KVector) { element.size = size }
        internal func getPosition() -> KVector { return element.getPosition() }
        internal func setPosition(_ pos: KVector) { element.position = pos }
        internal func getProperty<P>(_ prop: IProperty) -> P? { return element.getProperty(prop) as? P }
        internal func hasProperty(_ prop: IProperty) -> Bool { return element.hasProperty(prop) }
        internal func getVolatileId() -> Int { return element.id }
        internal func setVolatileId(_ id: Int) { element.id = id }

        internal func getGraph() -> GraphAdapter? { return parentGraphAdapter }

        internal func getLabels() -> [LabelAdapter] {
            if let cached = labelAdapters { return cached }
            let computed = element.getLabels().map { LLabelAdapter($0) }
            labelAdapters = computed
            return computed
        }

        internal func getPorts() -> [PortAdapter] {
            if let cached = portAdapters { return cached }
            let computed = element.getPorts().map { LPortAdapter($0, transparentNorthSouthEdges: transparentNorthSouthEdges) }
            portAdapters = computed
            return computed
        }

        internal func getIncomingEdges() -> [EdgeAdapter] { return [] }
        internal func getOutgoingEdges() -> [EdgeAdapter] { return [] }

        internal func sortPortList() {}
        internal func sortPortList(_ comparator: Any) {}

        internal func isCompoundNode() -> Bool {
            return element.getProperty(InternalProperties.COMPOUND_NODE) as? Bool ?? false
        }

        internal func getPadding() -> ElkPadding {
            let p = element.getPadding()
            return ElkPadding(p.top, p.right, p.bottom, p.left)
        }

        internal func setPadding(_ padding: ElkPadding) {
            let p = element.getPadding()
            p.set(padding.top, padding.right, padding.bottom, padding.left)
        }

        internal func getMargin() -> ElkMargin {
            let m = element.getMargin()
            return ElkMargin(m.top, m.right, m.bottom, m.left)
        }

        internal func setMargin(_ margin: ElkMargin) {
            let m = element.getMargin()
            m.set(margin.top, margin.right, margin.bottom, margin.left)
        }
    }

    // MARK: - LPortAdapter

    internal class LPortAdapter: PortAdapter {
        internal let element: LPort
        internal var labelAdapters: [LabelAdapter]?
        internal let transparentNorthSouthEdges: Bool

        init(_ element: LPort, transparentNorthSouthEdges: Bool) {
            self.element = element
            self.transparentNorthSouthEdges = transparentNorthSouthEdges
        }

        internal func getSize() -> KVector { return element.getSize() }
        internal func setSize(_ size: KVector) { element.size = size }
        internal func getPosition() -> KVector { return element.getPosition() }
        internal func setPosition(_ pos: KVector) { element.position = pos }
        internal func getProperty<P>(_ prop: IProperty) -> P? { return element.getProperty(prop) as? P }
        internal func hasProperty(_ prop: IProperty) -> Bool { return element.hasProperty(prop) }
        internal func getVolatileId() -> Int { return element.id }
        internal func setVolatileId(_ id: Int) { element.id = id }

        internal func getSide() -> PortSide { return element.getSide() }

        internal func getLabels() -> [LabelAdapter] {
            if let cached = labelAdapters { return cached }
            let computed = element.getLabels().map { LLabelAdapter($0) }
            labelAdapters = computed
            return computed
        }

        internal func getIncomingEdges() -> [EdgeAdapter] {
            return element.getIncomingEdges().map { LEdgeAdapter($0) }
        }

        internal func getOutgoingEdges() -> [EdgeAdapter] {
            return element.getOutgoingEdges().map { LEdgeAdapter($0) }
        }

        internal func hasCompoundConnections() -> Bool {
            return element.getProperty(InternalProperties.INSIDE_CONNECTIONS) as? Bool ?? false
        }
    }

    // MARK: - LLabelAdapter

    internal class LLabelAdapter: LabelAdapter {
        internal let element: LLabel

        init(_ element: LLabel) {
            self.element = element
        }

        internal func getSize() -> KVector { return element.getSize() }
        internal func setSize(_ size: KVector) { element.size = size }
        internal func getPosition() -> KVector { return element.getPosition() }
        internal func setPosition(_ pos: KVector) { element.position = pos }
        internal func getProperty<P>(_ prop: IProperty) -> P? { return element.getProperty(prop) as? P }
        internal func hasProperty(_ prop: IProperty) -> Bool { return element.hasProperty(prop) }
        internal func getVolatileId() -> Int { return element.id }
        internal func setVolatileId(_ id: Int) { element.id = id }

        internal func getSide() -> LabelSide {
            return element.getProperty(LabelSide.LABEL_SIDE) as? LabelSide ?? .UNKNOWN
        }

        internal func getText() -> String {
            return element.getText()
        }
    }

    // MARK: - LEdgeAdapter

    internal class LEdgeAdapter: EdgeAdapter {
        internal let element: LEdge

        init(_ edge: LEdge) {
            self.element = edge
        }

        internal func getSize() -> KVector { return KVector() }
        internal func setSize(_ size: KVector) {}
        internal func getPosition() -> KVector { return KVector() }
        internal func setPosition(_ pos: KVector) {}
        internal func getProperty<P>(_ prop: IProperty) -> P? { return element.getProperty(prop) as? P }
        internal func hasProperty(_ prop: IProperty) -> Bool { return element.hasProperty(prop) }
        internal func getVolatileId() -> Int { return element.id }
        internal func setVolatileId(_ id: Int) { element.id = id }

        internal func getLabels() -> [LabelAdapter] {
            return element.getLabels().map { LLabelAdapter($0) }
        }
    }
}
