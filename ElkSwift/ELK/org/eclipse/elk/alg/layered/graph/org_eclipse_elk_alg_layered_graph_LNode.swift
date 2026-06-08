// Copyright (c) 2010, 2019 Kiel University and others.
//
// This program and the accompanying materials are made available under the
// terms of the Eclipse Public License 2.0 which is available at
// http://www.eclipse.org/legal/epl-2.0.
//
// SPDX-License-Identifier: EPL-2.0

import Foundation

// MARK: - NodeType

internal enum NodeType: String {
    case normal = "NORMAL"
    case longEdge = "LONG_EDGE"
    case externalPort = "EXTERNAL_PORT"
    case northSouthPort = "NORTH_SOUTH_PORT"
    case label = "LABEL"
    case breakingPoint = "BREAKING_POINT"
    case placeholder = "PLACEHOLDER"
    case nonShiftingPlaceholder = "NONSHIFTING_PLACEHOLDER"

    internal static let NORMAL = NodeType.normal
    internal static let LONG_EDGE = NodeType.longEdge
    internal static let EXTERNAL_PORT = NodeType.externalPort
    internal static let NORTH_SOUTH_PORT = NodeType.northSouthPort
    internal static let LABEL = NodeType.label
    internal static let BREAKING_POINT = NodeType.breakingPoint
    internal static let PLACEHOLDER = NodeType.placeholder
    internal static let NONSHIFTING_PLACEHOLDER = NodeType.nonShiftingPlaceholder

    internal func getColor() -> String {
        switch self {
        case .externalPort: return "#cc99cc"
        case .longEdge: return "#eaed00"
        case .northSouthPort: return "#0034de"
        case .label: return "#75c3c3"
        case .breakingPoint: return "#eeeeff"
        default: return "#eeeeee"
        }
    }
}

// MARK: - LNode

internal class LNode: LShape {

    internal var graph: LGraph?
    internal var layer: Layer?
    internal var type: NodeType = .normal
    internal var ports: [LPort] = []
    internal var labels: [LLabel] = []
    internal var nestedGraph: LGraph?
    internal var margin = LMargin()
    internal var padding = LPadding()
    internal var portSideIndices: [PortSide: (Int, Int)]?
    internal var portSidesCached = false

    internal init(_ graph: LGraph) {
        self.graph = graph
    }

    internal override init() {
        super.init()
    }

    // MARK: - Layer Management

    internal func getLayer() -> Layer? {
        return layer
    }

    internal func setLayer(_ theLayer: Layer?) {
        if let oldLayer = layer {
            oldLayer.nodes.removeAll { $0 === self }
        }
        layer = theLayer
        if let newLayer = layer {
            newLayer.nodes.append(self)
        }
    }

    internal func setLayer(_ index: Int, _ theLayer: Layer) {
        if let oldLayer = layer {
            oldLayer.nodes.removeAll { $0 === self }
        }
        layer = theLayer
        theLayer.nodes.insert(self, at: min(index, theLayer.nodes.count))
    }

    // MARK: - Graph Management

    internal func getGraph() -> LGraph? {
        if graph == nil, let layer = layer {
            return layer.getGraph()
        }
        return graph
    }

    internal func setGraph(_ newGraph: LGraph) {
        graph = newGraph
    }

    // MARK: - Node Type

    internal func getType() -> NodeType {
        return type
    }

    internal func setType(_ type: NodeType) {
        self.type = type
    }

    // MARK: - Ports

    internal func getPorts() -> [LPort] {
        return ports
    }

    internal func getPorts(_ portType: PortType) -> [LPort] {
        switch portType {
        case .INPUT:
            return ports.filter { !$0.getIncomingEdges().isEmpty }
        case .OUTPUT:
            return ports.filter { !$0.getOutgoingEdges().isEmpty }
        default:
            return ports
        }
    }

    internal func getPorts(_ side: PortSide) -> [LPort] {
        return ports.filter { $0.getSide() == side }
    }

    internal func getPortSideView(_ side: PortSide) -> [LPort] {
        if !portSidesCached {
            findPortIndices()
        }
        guard let indices = portSideIndices?[side] else {
            return []
        }
        return Array(ports[indices.0..<indices.1])
    }

    /// Writes a reordered port list back into the node's `ports` array for the given side.
    /// This is needed because `getPortSideView` returns a value-type copy in Swift,
    /// whereas Java's `subList` returns a live view. Callers that reorder ports via the
    /// view must call this method to propagate changes back.
    internal func setPortSideView(_ side: PortSide, _ reorderedPorts: [LPort]) {
        if !portSidesCached {
            findPortIndices()
        }
        guard let indices = portSideIndices?[side] else { return }
        let range = indices.0..<indices.1
        guard range.count == reorderedPorts.count else { return }
        ports.replaceSubrange(range, with: reorderedPorts)
    }

    internal func getPorts(_ portType: PortType, _ side: PortSide) -> [LPort] {
        return getPorts(side).filter { port in
            switch portType {
            case .INPUT: return !port.getIncomingEdges().isEmpty
            case .OUTPUT: return !port.getOutgoingEdges().isEmpty
            default: return true
            }
        }
    }

    // MARK: - Edges

    internal func getIncomingEdges() -> [LEdge] {
        return ports.flatMap { $0.getIncomingEdges() }
    }

    internal func getOutgoingEdges() -> [LEdge] {
        return ports.flatMap { $0.getOutgoingEdges() }
    }

    internal func getConnectedEdges() -> [LEdge] {
        return ports.flatMap { $0.getIncomingEdges() + $0.getOutgoingEdges() }
    }

    // MARK: - Labels

    internal func getLabels() -> [LLabel] {
        return labels
    }

    // MARK: - Nested Graph

    internal func getNestedGraph() -> LGraph? {
        return nestedGraph
    }

    internal func setNestedGraph(_ nestedGraph: LGraph?) {
        self.nestedGraph = nestedGraph
    }

    // MARK: - Margin and Padding

    internal func getMargin() -> LMargin {
        return margin
    }

    internal func getPadding() -> LPadding {
        return padding
    }

    // MARK: - Coordinate Conversion

    /**
     * Converts the position of this node from coordinates relative to the parent node's border to
     * coordinates relative to that node's content area. The content area is the parent node border
     * minus padding minus offset.
     */
    internal func borderToContentAreaCoordinates(_ horizontal: Bool, _ vertical: Bool) {
        guard let thegraph = getGraph() else { return }

        let graphPadding = thegraph.getPadding()
        let offset = thegraph.getOffset()
        let pos = getPosition()

        if horizontal {
            pos.x = pos.x - graphPadding.left - offset.x
        }

        if vertical {
            pos.y = pos.y - graphPadding.top - offset.y
        }
    }

    // MARK: - Index

    internal func getIndex() -> Int {
        guard let layer = layer else { return -1 }
        return layer.nodes.firstIndex { $0 === self } ?? -1
    }

    // MARK: - Port Side Caching

    internal func cachePortSides() {
        portSidesCached = true
        findPortIndices()
    }

    internal func findPortIndices() {
        var indices: [PortSide: (Int, Int)] = [:]
        var firstIndexForCurrentSide = 0
        var currentSide = PortSide.NORTH
        var currentIndex = 0

        for port in ports {
            if port.getSide() != currentSide {
                if firstIndexForCurrentSide != currentIndex {
                    indices[currentSide] = (firstIndexForCurrentSide, currentIndex)
                }
                currentSide = port.getSide()
                firstIndexForCurrentSide = currentIndex
            }
            currentIndex += 1
        }

        indices[currentSide] = (firstIndexForCurrentSide, currentIndex)
        self.portSideIndices = indices
    }

    // MARK: - Interactive Reference

    /// Returns the center of the node (position + half size), used by interactive strategies.
    internal func getInteractiveReferencePoint() -> KVector {
        return KVector(getPosition().x + getSize().x / 2, getPosition().y + getSize().y / 2)
    }

    internal func isInlineEdgeLabel() -> Bool {
        guard type == .label else { return false }
        let representedLabels = getProperty(InternalProperties.REPRESENTED_LABELS) as? [LLabel] ?? []
        return representedLabels.allSatisfy { label in
            label.getProperty(LayeredOptions.EDGE_LABELS_INLINE) as? Bool ?? false
        }
    }

    // MARK: - Designation

    internal override func getDesignation() -> String? {
        if !labels.isEmpty, let firstLabel = labels.first {
            let text = firstLabel.getText()
            if !text.isEmpty {
                return text
            }
        }
        if let designation = super.getDesignation(), !designation.isEmpty {
            return designation
        }
        return String(getIndex())
    }

    // MARK: - String Representation

    internal func toString() -> String {
        var result = "n"
        if type != .normal {
            result += "(\(type.rawValue.lowercased()))"
        }
        result += "_\(getDesignation() ?? "")"
        return result
    }
}
