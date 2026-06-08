import Foundation

internal final class org_eclipse_elk_alg_layered_intermediate_loops_SelfHyperLoop {

    // Structural properties
    private let slHolder: SelfLoopHolder
    private var slPorts: [SelfLoopPort] = []
    private var slEdges: Set<SelfLoopEdge> = []
    private var slLabels: SelfHyperLoopLabels?

    // Routing properties
    private var selfLoopType: SelfLoopType?
    private var slPortsBySide: [PortSide: [SelfLoopPort]]?
    private var leftmostPort: SelfLoopPort?
    private var rightmostPort: SelfLoopPort?
    private var occupiedPortSides: Set<PortSide> = []
    private var routingSlot: [Int] = [Int](repeating: 0, count: 5) // PortSide.values().count

    init(_ slHolder: SelfLoopHolder) {
        self.slHolder = slHolder
    }

    /// Fills slPortsBySide and determines the self loop type. Called by PortRestorer.
    internal func computePortsPerSide() {
        var portsBySide = [PortSide: [SelfLoopPort]]()
        for slPort in slPorts {
            let portSide = slPort.getLPort().getSide()
            portsBySide[portSide, default: []].append(slPort)
        }
        slPortsBySide = portsBySide
        selfLoopType = SelfLoopType.fromPortSides(Set(portsBySide.keys))
    }

    // MARK: - Accessors

    internal func getSLHolder() -> SelfLoopHolder {
        return slHolder
    }

    internal func addSelfLoopEdge(_ slEdge: SelfLoopEdge) {
        if slEdges.insert(slEdge).inserted {
            slEdge.setSLHyperLoop(self)

            let slSource = slEdge.getSLSource()
            if !slPorts.contains(where: { $0 === slSource }) {
                slPorts.append(slSource)
            }

            let slTarget = slEdge.getSLTarget()
            if !slPorts.contains(where: { $0 === slTarget }) {
                slPorts.append(slTarget)
            }

            // Check if we need to take care of any edge labels
            let lLabels = slEdge.getLEdge().getLabels()
            if !lLabels.isEmpty {
                if slLabels == nil {
                    slLabels = SelfHyperLoopLabels(self)
                }
                slLabels?.addLLabels(lLabels)
            }
        }
    }

    internal func getSLPorts() -> [SelfLoopPort] {
        return slPorts
    }

    /// Mutable access to slPorts for sorting.
    internal func sortSLPorts(by comparator: (SelfLoopPort, SelfLoopPort) -> Bool) {
        slPorts.sort(by: comparator)
    }

    internal func getSLEdges() -> Set<SelfLoopEdge> {
        return slEdges
    }

    internal func getSLLabels() -> SelfHyperLoopLabels? {
        return slLabels
    }

    internal func getSelfLoopType() -> SelfLoopType? {
        return selfLoopType
    }

    internal func getSLPortsBySide() -> [PortSide: [SelfLoopPort]] {
        return slPortsBySide ?? [:]
    }

    internal func getSLPortsBySide(_ portSide: PortSide) -> [SelfLoopPort] {
        return slPortsBySide?[portSide] ?? []
    }

    internal func hasSLPortsOnSide(_ portSide: PortSide) -> Bool {
        guard let ports = slPortsBySide?[portSide] else { return false }
        return !ports.isEmpty
    }

    internal func getLeftmostPort() -> SelfLoopPort? {
        return leftmostPort
    }

    internal func setLeftmostPort(_ port: SelfLoopPort) {
        self.leftmostPort = port
    }

    internal func getRightmostPort() -> SelfLoopPort? {
        return rightmostPort
    }

    internal func setRightmostPort(_ port: SelfLoopPort) {
        self.rightmostPort = port
    }

    internal func getOccupiedPortSides() -> Set<PortSide> {
        return occupiedPortSides
    }

    internal func addOccupiedPortSide(_ side: PortSide) {
        occupiedPortSides.insert(side)
    }

    internal func getRoutingSlot(_ portSide: PortSide) -> Int {
        return routingSlot[portSide.ordinal]
    }

    internal func setRoutingSlot(_ portSide: PortSide, _ slot: Int) {
        routingSlot[portSide.ordinal] = slot

        let slotCount = slHolder.getRoutingSlotCount()
        slotCount[portSide.ordinal] = max(slotCount[portSide.ordinal], slot + 1)
    }
}
