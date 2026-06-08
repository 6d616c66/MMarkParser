/*******************************************************************************
 * Copyright (c) 2010, 2019 Kiel University and others.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License 2.0 which is available at
 * http://www.eclipse.org/legal/epl-2.0.
 *
 * SPDX-License-Identifier: EPL-2.0
 *******************************************************************************/

import Foundation

internal typealias Predicate<T> = (T) -> Bool

/**
 * A port in a layered graph.
 */
internal final class LPort: LShape {

    internal static let OUTPUT_PREDICATE: Predicate<LPort> = { !$0.outgoingEdges.isEmpty }
    internal static let INPUT_PREDICATE: Predicate<LPort> = { !$0.incomingEdges.isEmpty }
    internal static let NORTH_PREDICATE: Predicate<LPort> = { $0.side == .NORTH }
    internal static let EAST_PREDICATE: Predicate<LPort> = { $0.side == .EAST }
    internal static let SOUTH_PREDICATE: Predicate<LPort> = { $0.side == .SOUTH }
    internal static let WEST_PREDICATE: Predicate<LPort> = { $0.side == .WEST }

    internal weak var owner: LNode?
    internal var side: PortSide = .UNDEFINED
    internal var anchor: KVector = KVector()
    internal var explicitlySuppliedPortAnchor = false
    internal var margin = LMargin()
    internal var labels: [LLabel] = []
    internal var incomingEdges: [LEdge] = []
    internal var outgoingEdges: [LEdge] = []
    internal var connectedToExternalNodes = true

    /// Alias for owner, for code that accesses `port.node`
    internal var node: LNode? {
        get { return owner }
        set { owner = newValue }
    }

    internal var isInput: Bool { !incomingEdges.isEmpty }
    internal var isOutput: Bool { !outgoingEdges.isEmpty }

    /// Computed property returning position + anchor (same as getAbsoluteAnchor()).
    internal var absoluteAnchor: KVector {
        return getAbsoluteAnchor()
    }

    /// The number of connected edges (incoming + outgoing).
    internal var degree: Int {
        return incomingEdges.count + outgoingEdges.count
    }

    internal func getNode() -> LNode? {
        return owner
    }

    internal func setNode(_ node: LNode?) {
        if let oldOwner = owner {
            oldOwner.ports.removeAll { $0 === self }
        }
        owner = node
        if let newOwner = owner {
            newOwner.ports.append(self)
        }
    }

    internal func getSide() -> PortSide {
        return side
    }

    internal func setSide(_ theside: PortSide) {
        guard theside != .UNDEFINED else { return }
        side = theside
        if !explicitlySuppliedPortAnchor {
            switch side {
            case .NORTH:
                anchor.x = getSize().x / 2
                anchor.y = 0
            case .EAST:
                anchor.x = getSize().x
                anchor.y = getSize().y / 2
            case .SOUTH:
                anchor.x = getSize().x / 2
                anchor.y = getSize().y
            case .WEST:
                anchor.x = 0
                anchor.y = getSize().y / 2
            default:
                break
            }
        }
    }

    internal func getAnchor() -> KVector {
        return anchor
    }

    internal func isExplicitlySuppliedPortAnchor() -> Bool {
        return explicitlySuppliedPortAnchor
    }

    internal func setExplicitlySuppliedPortAnchor(_ fixed: Bool) {
        explicitlySuppliedPortAnchor = fixed
    }

    internal func getAbsoluteAnchor() -> KVector {
        guard let ownerPos = owner?.getPosition() else { return KVector() }
        let myPos = getPosition()
        return KVector(ownerPos.x + myPos.x + anchor.x, ownerPos.y + myPos.y + anchor.y)
    }

    internal func getMargin() -> LMargin {
        return margin
    }

    internal func getLabels() -> [LLabel] {
        return labels
    }

    internal func getName() -> String? {
        if !labels.isEmpty {
            return labels[0].getText()
        }
        return nil
    }

    internal func getDegree() -> Int {
        return incomingEdges.count + outgoingEdges.count
    }

    internal func getNetFlow() -> Int {
        return incomingEdges.count - outgoingEdges.count
    }

    internal func getIncomingEdges() -> [LEdge] {
        return incomingEdges
    }

    internal func getOutgoingEdges() -> [LEdge] {
        return outgoingEdges
    }

    internal func getConnectedEdges() -> [LEdge] {
        return incomingEdges + outgoingEdges
    }

    internal func isConnectedToExternalNodes() -> Bool {
        return connectedToExternalNodes
    }

    internal func setConnectedToExternalNodes(_ conn: Bool) {
        connectedToExternalNodes = conn
    }

    internal func getPredecessorPorts() -> [LPort] {
        return incomingEdges.compactMap { $0.getSource() }
    }

    internal func getSuccessorPorts() -> [LPort] {
        return outgoingEdges.compactMap { $0.getTarget() }
    }

    internal func getConnectedPorts() -> [LPort] {
        return getPredecessorPorts() + getSuccessorPorts()
    }

    internal func getIndex() -> Int {
        guard let owner = owner else { return -1 }
        return owner.ports.firstIndex { $0 === self } ?? -1
    }

    internal override func getDesignation() -> String? {
        if !labels.isEmpty {
            let text = labels[0].getText()
            if !text.isEmpty {
                return text
            }
        }
        if let designation = super.getDesignation(), !designation.isEmpty {
            return designation
        }
        return String(getIndex())
    }

    internal func toString() -> String {
        var result = "p_\(getDesignation() ?? "")"
        if let owner = owner {
            result += "[\(owner)]"
        }
        return result
    }
}
