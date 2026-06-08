// Partially ported from elk-source/plugins/org.eclipse.elk.alg.layered/src/org/eclipse/elk/alg/layered/intermediate/preserveorder/ModelOrderPortComparator.java
import Foundation

internal class org_eclipse_elk_alg_layered_intermediate_preserveorder_ModelOrderPortComparator {
    internal var previousLayer: [LNode] = []
    internal var graph: LGraph?
    internal var strategy: OrderingStrategy = .NONE
    internal var targetNodeModelOrder: [ObjectIdentifier: Int]?
    internal var portModelOrder: Bool = false

    internal init() {}

    internal convenience init(
        _ graph: LGraph,
        _ previousLayer: Layer,
        _ strategy: OrderingStrategy,
        _ targetNodeModelOrder: [ObjectIdentifier: Int]?,
        _ portModelOrder: Bool
    ) {
        self.init(graph, previousLayer.getNodes(), strategy, targetNodeModelOrder, portModelOrder)
    }

    internal init(
        _ graph: LGraph,
        _ previousLayer: [LNode],
        _ strategy: OrderingStrategy,
        _ targetNodeModelOrder: [ObjectIdentifier: Int]?,
        _ portModelOrder: Bool
    ) {
        self.graph = graph
        self.previousLayer = previousLayer
        self.strategy = strategy
        self.targetNodeModelOrder = targetNodeModelOrder
        self.portModelOrder = portModelOrder
    }

    internal func compare(
        _ p1: LPort,
        _ p2: LPort
    ) -> Int {
        // Minimal compile-safe behavior while full Java comparator remains to be ported.
        if p1 === p2 {
            return 0
        }
        if p1.getSide() != p2.getSide() {
            return sideOrder(p1.getSide()) < sideOrder(p2.getSide()) ? -1 : 1
        }
        return ObjectIdentifier(p1).hashValue < ObjectIdentifier(p2).hashValue ? -1 : 1
    }

    internal func sideOrder(_ side: PortSide) -> Int {
        switch side {
        case .NORTH:
            return 0
        case .EAST:
            return 1
        case .SOUTH:
            return 2
        case .WEST:
            return 3
        case .UNDEFINED:
            return -1
        }
    }
}
