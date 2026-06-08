// Ported from elk-source/plugins/org.eclipse.elk.alg.layered/src/org/eclipse/elk/alg/layered/p5edges/orthogonal/HyperEdgeSegment.java

import Foundation

// typealias HyperEdgeSegment is defined in TypeAliases.swift

internal class org_eclipse_elk_alg_layered_p5edges_orthogonal_HyperEdgeSegment: Comparable, Hashable {

    // MARK: - Properties

    /// routing strategy which will ultimately decide how edges will be routed.
    internal let routingStrategy: org_eclipse_elk_alg_layered_p5edges_orthogonal_direction_BaseRoutingDirectionStrategy

    /// ports represented by this hypernode.
    internal var ports: [org_eclipse_elk_alg_layered_graph_LPort] = []

    /// mark value used for cycle breaking (to be accessed directly).
    internal var mark: Int = 0

    /// the routing slot determines the horizontal distance to the preceding layer.
    internal var routingSlot: Int = 0

    /// start position of this edge segment (in horizontal layouts, this is the topmost y coordinate).
    internal var startPosition: Double = .nan
    /// end position of this edge segment (in horizontal layouts, this is the bottommost y coordinate).
    internal var endPosition: Double = .nan

    /// sorted list of coordinates where incoming connections enter this segment.
    internal var incomingConnectionCoordinates: [Double] = []
    /// sorted list of coordinates where outgoing connections leave this segment.
    internal var outgoingConnectionCoordinates: [Double] = []

    /// list of outgoing dependencies to other edge segments.
    internal var outgoingSegmentDeps: [org_eclipse_elk_alg_layered_p5edges_orthogonal_HyperEdgeSegmentDependency] = []
    /// combined weight of all outgoing dependencies.
    internal var outDepWeight: Int = 0
    /// combined weight of critical outgoing dependencies.
    internal var criticalOutDepWeight: Int = 0
    /// list of incoming dependencies from other edge segments.
    internal var incomingSegmentDeps: [org_eclipse_elk_alg_layered_p5edges_orthogonal_HyperEdgeSegmentDependency] = []
    /// combined weight of all incoming dependencies.
    internal var inDepWeight: Int = 0
    /// combined weight of critical incoming dependencies.
    internal var criticalInDepWeight: Int = 0

    /// if this segment is the result of a split segment, this is the other segment; otherwise it is nil.
    internal var splitPartner: org_eclipse_elk_alg_layered_p5edges_orthogonal_HyperEdgeSegment?
    /// the segment that caused this segment to be split, if any (only set on one of the split partners).
    internal var splitBy: org_eclipse_elk_alg_layered_p5edges_orthogonal_HyperEdgeSegment?

    // MARK: - Initialization

    internal init(_ routingStrategy: org_eclipse_elk_alg_layered_p5edges_orthogonal_direction_BaseRoutingDirectionStrategy) {
        self.routingStrategy = routingStrategy
    }

    /// Only used internally - should not be called externally.
    internal init() {
        self.routingStrategy = org_eclipse_elk_alg_layered_p5edges_orthogonal_direction_BaseRoutingDirectionStrategy()
    }

    /// Adds the positions of the given port and all connected ports.
    internal func addPortPositions(
        _ port: org_eclipse_elk_alg_layered_graph_LPort,
        _ hyperEdgeSegmentMap: inout [ObjectIdentifier: org_eclipse_elk_alg_layered_p5edges_orthogonal_HyperEdgeSegment]
    ) {
        hyperEdgeSegmentMap[ObjectIdentifier(port)] = self
        ports.append(port)
        let portPos = routingStrategy.getPortPositionOnHyperNode(port)

        // add the new port position to the respective list
        if port.getSide() == routingStrategy.getSourcePortSide() {
            Self.insertSorted(&incomingConnectionCoordinates, portPos)
        } else {
            Self.insertSorted(&outgoingConnectionCoordinates, portPos)
        }

        // update start and end coordinates
        recomputeExtent()

        // add connected ports
        for otherPort in port.getConnectedPorts() {
            if hyperEdgeSegmentMap[ObjectIdentifier(otherPort)] == nil {
                addPortPositions(otherPort, &hyperEdgeSegmentMap)
            }
        }
    }

    internal static func insertSorted(_ list: inout [Double], _ value: Double) {
        var insertIndex = list.count
        for i in 0..<list.count {
            let next = Float(list[i])
            if next == Float(value) {
                // an exactly equal value is already present in the list
                return
            } else if Double(next) > value {
                insertIndex = i
                break
            }
        }
        list.insert(value, at: insertIndex)
    }

    // MARK: - Getters and Setters

    /// Returns the ports incident to this segment.
    internal func getPorts() -> [org_eclipse_elk_alg_layered_graph_LPort] {
        return ports
    }

    /// Returns this segment's routing slot.
    internal func getRoutingSlot() -> Int {
        return routingSlot
    }

    /// Sets this segment's routing slot.
    internal func setRoutingSlot(_ slot: Int) {
        self.routingSlot = slot
    }

    /// Returns the coordinate where this segment begins.
    internal func getStartCoordinate() -> Double {
        return startPosition
    }

    /// Returns the coordinate where this segment ends.
    internal func getEndCoordinate() -> Double {
        return endPosition
    }

    /// Returns the (sorted) list of coordinates where incoming connections enter this segment.
    internal func getIncomingConnectionCoordinates() -> [Double] {
        return incomingConnectionCoordinates
    }

    /// Sets the incoming connection coordinates (used internally by split operations).
    internal func setIncomingConnectionCoordinates(_ coords: [Double]) {
        incomingConnectionCoordinates = coords
    }

    /// Returns the (sorted) list of coordinates where outgoing connections leave this segment.
    internal func getOutgoingConnectionCoordinates() -> [Double] {
        return outgoingConnectionCoordinates
    }

    /// Sets the outgoing connection coordinates (used internally by split operations).
    internal func setOutgoingConnectionCoordinates(_ coords: [Double]) {
        outgoingConnectionCoordinates = coords
    }

    /// Return the outgoing dependencies to other hyper edge segments.
    internal func getOutgoingSegmentDependencies() -> [org_eclipse_elk_alg_layered_p5edges_orthogonal_HyperEdgeSegmentDependency] {
        return outgoingSegmentDeps
    }

    internal func appendOutgoingSegmentDependency(_ dep: org_eclipse_elk_alg_layered_p5edges_orthogonal_HyperEdgeSegmentDependency) {
        outgoingSegmentDeps.append(dep)
    }

    internal func removeOutgoingSegmentDependency(_ dep: org_eclipse_elk_alg_layered_p5edges_orthogonal_HyperEdgeSegmentDependency) {
        outgoingSegmentDeps.removeAll(where: { $0 === dep })
    }

    /// Returns the combined weight of all outgoing dependencies.
    internal func getOutWeight() -> Int {
        return outDepWeight
    }

    /// Sets the combined weight of all outgoing dependencies.
    internal func setOutWeight(_ outWeight: Int) {
        self.outDepWeight = outWeight
    }

    /// Returns the combined weight of critical outgoing dependencies.
    internal func getCriticalOutWeight() -> Int {
        return criticalOutDepWeight
    }

    /// Sets the combined weight of critical outgoing dependencies.
    internal func setCriticalOutWeight(_ outWeight: Int) {
        self.criticalOutDepWeight = outWeight
    }

    /// Return the incoming dependencies from other hyper edge segments.
    internal func getIncomingSegmentDependencies() -> [org_eclipse_elk_alg_layered_p5edges_orthogonal_HyperEdgeSegmentDependency] {
        return incomingSegmentDeps
    }

    internal func appendIncomingSegmentDependency(_ dep: org_eclipse_elk_alg_layered_p5edges_orthogonal_HyperEdgeSegmentDependency) {
        incomingSegmentDeps.append(dep)
    }

    internal func removeIncomingSegmentDependency(_ dep: org_eclipse_elk_alg_layered_p5edges_orthogonal_HyperEdgeSegmentDependency) {
        incomingSegmentDeps.removeAll(where: { $0 === dep })
    }

    /// Returns the weight of incoming dependencies.
    internal func getInWeight() -> Int {
        return inDepWeight
    }

    /// Sets the weight of incoming dependencies.
    internal func setInWeight(_ inWeight: Int) {
        self.inDepWeight = inWeight
    }

    /// Returns the combined weight of critical incoming dependencies.
    internal func getCriticalInWeight() -> Int {
        return criticalInDepWeight
    }

    /// Sets the combined weight of critical incoming dependencies.
    internal func setCriticalInWeight(_ inWeight: Int) {
        self.criticalInDepWeight = inWeight
    }

    /// Returns the split partner.
    internal func getSplitPartner() -> org_eclipse_elk_alg_layered_p5edges_orthogonal_HyperEdgeSegment? {
        return splitPartner
    }

    /// Sets the split partner.
    internal func setSplitPartner(_ splitPartner: org_eclipse_elk_alg_layered_p5edges_orthogonal_HyperEdgeSegment?) {
        self.splitPartner = splitPartner
    }

    /// Returns the segment that caused this one to be split, if any.
    internal func getSplitBy() -> org_eclipse_elk_alg_layered_p5edges_orthogonal_HyperEdgeSegment? {
        return splitBy
    }

    /// Sets the segment that caused this one to be split, if any.
    internal func setSplitBy(_ splitBy: org_eclipse_elk_alg_layered_p5edges_orthogonal_HyperEdgeSegment?) {
        self.splitBy = splitBy
    }

    // MARK: - Utilities

    /// Returns the length of this segment (end - start).
    internal func getLength() -> Double {
        return getEndCoordinate() - getStartCoordinate()
    }

    /// Checks whether this segment connects two or more ports.
    internal func representsHyperedge() -> Bool {
        return getIncomingConnectionCoordinates().count + getOutgoingConnectionCoordinates().count > 2
    }

    /// Checks whether this segment was introduced while splitting another segment.
    internal func isDummy() -> Bool {
        return splitPartner != nil && splitBy == nil
    }

    /// Recomputes the start and end coordinate based on incoming and outgoing connection coordinates.
    internal func recomputeExtent() {
        startPosition = .nan
        endPosition = .nan

        recomputeExtentFromPositions(incomingConnectionCoordinates)
        recomputeExtentFromPositions(outgoingConnectionCoordinates)
    }

    internal func recomputeExtentFromPositions(_ positions: [Double]) {
        // this code assumes that the positions are sorted ascendingly
        guard let first = positions.first, let last = positions.last else { return }
        // set new start position
        if startPosition.isNaN {
            startPosition = first
        } else {
            startPosition = min(startPosition, first)
        }

        // set new end position
        if endPosition.isNaN {
            endPosition = last
        } else {
            endPosition = max(endPosition, last)
        }
    }

    // MARK: - Splitting

    /// Simulates what would happen during a split.
    internal func simulateSplit() -> (org_eclipse_elk_alg_layered_p5edges_orthogonal_HyperEdgeSegment, org_eclipse_elk_alg_layered_p5edges_orthogonal_HyperEdgeSegment) {
        let newSplit = org_eclipse_elk_alg_layered_p5edges_orthogonal_HyperEdgeSegment(routingStrategy)
        let newSplitPartner = org_eclipse_elk_alg_layered_p5edges_orthogonal_HyperEdgeSegment(routingStrategy)

        newSplit.incomingConnectionCoordinates.append(contentsOf: incomingConnectionCoordinates)
        newSplit.splitBy = splitBy
        newSplit.splitPartner = newSplitPartner
        newSplit.recomputeExtent()

        newSplitPartner.outgoingConnectionCoordinates.append(contentsOf: outgoingConnectionCoordinates)
        newSplitPartner.splitPartner = newSplit
        newSplitPartner.recomputeExtent()

        return (newSplit, newSplitPartner)
    }

    /// Splits this segment into two and returns the new segment.
    internal func splitAt(_ splitPosition: Double) -> org_eclipse_elk_alg_layered_p5edges_orthogonal_HyperEdgeSegment {
        let partner = org_eclipse_elk_alg_layered_p5edges_orthogonal_HyperEdgeSegment(routingStrategy)
        splitPartner = partner
        partner.setSplitPartner(self)

        // Move all target positions over to the new segment
        partner.outgoingConnectionCoordinates.append(contentsOf: outgoingConnectionCoordinates)
        self.outgoingConnectionCoordinates.removeAll()

        // Link the two
        self.outgoingConnectionCoordinates.append(splitPosition)
        partner.incomingConnectionCoordinates.append(splitPosition)

        // Recompute their outer coordinates
        self.recomputeExtent()
        partner.recomputeExtent()

        // Clear dependencies so they can be regenerated later
        while !incomingSegmentDeps.isEmpty {
            incomingSegmentDeps[0].remove()
        }

        while !outgoingSegmentDeps.isEmpty {
            outgoingSegmentDeps[0].remove()
        }

        return partner
    }

    // MARK: - Comparable and Hashable

    internal static func < (lhs: org_eclipse_elk_alg_layered_p5edges_orthogonal_HyperEdgeSegment,
                          rhs: org_eclipse_elk_alg_layered_p5edges_orthogonal_HyperEdgeSegment) -> Bool {
        return lhs.mark < rhs.mark
    }

    internal static func == (lhs: org_eclipse_elk_alg_layered_p5edges_orthogonal_HyperEdgeSegment,
                           rhs: org_eclipse_elk_alg_layered_p5edges_orthogonal_HyperEdgeSegment) -> Bool {
        return lhs.mark == rhs.mark
    }

    internal func hash(into hasher: inout Hasher) {
        hasher.combine(mark)
    }
}
