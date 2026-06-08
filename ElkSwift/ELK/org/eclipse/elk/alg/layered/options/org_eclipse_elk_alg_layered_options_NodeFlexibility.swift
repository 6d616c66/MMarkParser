// Ported from elk-source/plugins/org.eclipse.elk.alg.layered/src/org/eclipse/elk/alg/layered/options/NodeFlexibility.java

import Foundation

internal enum org_eclipse_elk_alg_layered_options_NodeFlexibility {
    internal enum _Keys {
        static let nodeFlexibility = Property<Any>(
            "org.eclipse.elk.layered.nodePlacement.networkSimplex.nodeFlexibility")
        static let nodeFlexibilityDefault = Property<Any>(
            "org.eclipse.elk.layered.nodePlacement.networkSimplex.nodeFlexibility.default")
    }

    case NONE
    case PORT_POSITION
    case NODE_SIZE_WHERE_SPACE_PERMITS
    case NODE_SIZE

    internal func isFlexibleSize() -> Bool {
        self == .NODE_SIZE
    }

    internal func isFlexibleSizeWhereSpacePermits() -> Bool {
        self == .NODE_SIZE_WHERE_SPACE_PERMITS || self == .NODE_SIZE
    }

    internal func isFlexiblePorts() -> Bool {
        self == .PORT_POSITION || self == .NODE_SIZE_WHERE_SPACE_PERMITS || self == .NODE_SIZE
    }

    internal func isAtLeast(_ nf: org_eclipse_elk_alg_layered_options_NodeFlexibility) -> Bool {
        switch self {
        case .NODE_SIZE:
            return nf.isFlexibleSize()
        case .NODE_SIZE_WHERE_SPACE_PERMITS:
            _ = nf.isFlexibleSizeWhereSpacePermits()
            fallthrough
        case .PORT_POSITION:
            return nf.isFlexiblePorts()
        case .NONE:
            return true
        }
    }

    internal static func getNodeFlexibility(
        _ lNode: org_eclipse_elk_alg_layered_graph_LNode
    ) -> org_eclipse_elk_alg_layered_options_NodeFlexibility {
        if lNode.hasProperty(_Keys.nodeFlexibility) {
            return lNode.getProperty(_Keys.nodeFlexibility) as? org_eclipse_elk_alg_layered_options_NodeFlexibility ?? .NONE
        }
        return lNode.getGraph()?.getProperty(_Keys.nodeFlexibilityDefault) as? org_eclipse_elk_alg_layered_options_NodeFlexibility ?? .NONE
    }
}
