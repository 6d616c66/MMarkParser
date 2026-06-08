// Ported from elk-source/plugins/org.eclipse.elk.alg.layered/src/org/eclipse/elk/alg/layered/options/LongEdgeOrderingStrategy.java

import Foundation

internal enum org_eclipse_elk_alg_layered_options_LongEdgeOrderingStrategy {
    case DUMMY_NODE_OVER
    case DUMMY_NODE_UNDER
    case EQUAL

    internal func returnValue() -> Int {
        switch self {
        case .DUMMY_NODE_OVER:
            return Int(Int32.max)
        case .DUMMY_NODE_UNDER:
            return Int(Int32.min)
        case .EQUAL:
            return 0
        }
    }
}
