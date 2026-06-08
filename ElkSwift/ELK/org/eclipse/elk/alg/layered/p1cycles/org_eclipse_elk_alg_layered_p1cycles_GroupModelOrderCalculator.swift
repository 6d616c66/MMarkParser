// Generated from ELK Java source
// Source of truth: elk-source (Java)
// DO NOT EDIT MANUALLY. Regenerate instead.

// Java source: plugins/org.eclipse.elk.alg.layered/src/org/eclipse/elk/alg/layered/p1cycles/GroupModelOrderCalculator.java

import Foundation

internal enum org_eclipse_elk_alg_layered_p1cycles_ModelOrderPropertyScaffolding {
    internal enum Keys {
        static let layerConstraint = "LAYERING_LAYER_CONSTRAINT"
        static let modelOrder = "INTERNAL_MODEL_ORDER"
        static let cycleBreakingGroupId = "MODEL_ORDER_CYCLE_BREAKING_ID"
        static let groupOrderStrategy = "CONSIDER_MODEL_ORDER_GROUP_MODEL_ORDER_CB_GROUP_ORDER_STRATEGY"
        static let maxModelOrderNodes = "INTERNAL_MAX_MODEL_ORDER_NODES"
        static let cbNumModelOrderGroups = "INTERNAL_CB_NUM_MODEL_ORDER_GROUPS"
    }

    // These scaffolding maps have no writers in the current port; kept immutable
    // so a future regression cannot reintroduce a process-wide mutable singleton
    // that would race under concurrent renders. If real writers are ever needed,
    // move the state onto the owning LGraph/LNode instead of a static map.
    internal static let layerConstraintByNode: [ObjectIdentifier: org_eclipse_elk_alg_layered_options_LayerConstraint] = [:]
    internal static let modelOrderByNode: [ObjectIdentifier: Int] = [:]
    internal static let cycleBreakingGroupIdByNode: [ObjectIdentifier: Int] = [:]
    internal static let groupOrderStrategyByGraph: [ObjectIdentifier: org_eclipse_elk_alg_layered_options_GroupOrderStrategy] = [:]
    internal static let maxModelOrderNodesByGraph: [ObjectIdentifier: Int] = [:]
    internal static let cbNumModelOrderGroupsByGraph: [ObjectIdentifier: Int] = [:]

    internal static func layerConstraint(
        for node: org_eclipse_elk_alg_layered_graph_LNode
    ) -> org_eclipse_elk_alg_layered_options_LayerConstraint? {
        layerConstraintByNode[ObjectIdentifier(node)]
    }

    internal static func modelOrder(for node: org_eclipse_elk_alg_layered_graph_LNode) -> Int? {
        modelOrderByNode[ObjectIdentifier(node)]
    }

    internal static func cycleBreakingGroupId(for node: org_eclipse_elk_alg_layered_graph_LNode) -> Int? {
        cycleBreakingGroupIdByNode[ObjectIdentifier(node)]
    }

    internal static func groupOrderStrategy(
        for graph: org_eclipse_elk_alg_layered_graph_LGraph?
    ) -> org_eclipse_elk_alg_layered_options_GroupOrderStrategy? {
        guard let graph else {
            return nil
        }
        return groupOrderStrategyByGraph[ObjectIdentifier(graph)]
    }

    internal static func maxModelOrderNodes(for graph: org_eclipse_elk_alg_layered_graph_LGraph?) -> Int? {
        guard let graph else {
            return nil
        }
        return maxModelOrderNodesByGraph[ObjectIdentifier(graph)]
    }

    internal static func cbNumModelOrderGroups(for graph: org_eclipse_elk_alg_layered_graph_LGraph?) -> Int? {
        guard let graph else {
            return nil
        }
        return cbNumModelOrderGroupsByGraph[ObjectIdentifier(graph)]
    }
}

internal class org_eclipse_elk_alg_layered_p1cycles_GroupModelOrderCalculator {
    internal var firstSeparateNodes = 0
    internal var lastSeparateNodes = 0

    internal init() {}

    internal func computeConstraintModelOrder(
        _ node: org_eclipse_elk_alg_layered_graph_LNode,
        _ offset: Int
    ) -> Int {
        var modelOrder = 0
        switch layerConstraint(for: node) {
        case .FIRST_SEPARATE:
            modelOrder = (2 * -offset) + firstSeparateNodes
            firstSeparateNodes += 1
        case .FIRST:
            modelOrder = -offset
        case .LAST:
            modelOrder = offset
        case .LAST_SEPARATE:
            modelOrder = (2 * offset) + lastSeparateNodes
            lastSeparateNodes += 1
        case .NONE:
            break
        }

        if let nodeModelOrder = modelOrderProperty(for: node) {
            modelOrder += nodeModelOrder
        }
        return modelOrder
    }

    internal func computeConstraintGroupModelOrder(
        _ node: org_eclipse_elk_alg_layered_graph_LNode,
        _ offset: Int,
        _ smallOffset: Int
    ) -> Int {
        var modelOrder = 0
        switch layerConstraint(for: node) {
        case .FIRST_SEPARATE:
            modelOrder = (2 * -offset) + firstSeparateNodes
            firstSeparateNodes += 1
        case .FIRST:
            modelOrder = -offset
        case .LAST:
            modelOrder = offset
        case .LAST_SEPARATE:
            modelOrder = (2 * offset) + lastSeparateNodes
            lastSeparateNodes += 1
        case .NONE:
            break
        }

        if let components = groupModelOrderComponents(for: node) {
            modelOrder += (components.groupId * smallOffset) + components.modelOrder
        }
        return modelOrder
    }

    internal func resetInternalCounters() {
        firstSeparateNodes = 0
        lastSeparateNodes = 0
    }

    internal func layerConstraint(
        for node: org_eclipse_elk_alg_layered_graph_LNode
    ) -> org_eclipse_elk_alg_layered_options_LayerConstraint {
        org_eclipse_elk_alg_layered_p1cycles_ModelOrderPropertyScaffolding
            .layerConstraint(for: node) ?? .NONE
    }

    internal func modelOrderProperty(for node: org_eclipse_elk_alg_layered_graph_LNode) -> Int? {
        org_eclipse_elk_alg_layered_p1cycles_ModelOrderPropertyScaffolding
            .modelOrder(for: node) ?? node.id
    }

    internal func groupModelOrderComponents(
        for node: org_eclipse_elk_alg_layered_graph_LNode
    ) -> (groupId: Int, modelOrder: Int)? {
        guard let modelOrder = modelOrderProperty(for: node) else {
            return nil
        }
        let groupId = org_eclipse_elk_alg_layered_p1cycles_ModelOrderPropertyScaffolding
            .cycleBreakingGroupId(for: node) ?? 0
        return (groupId: groupId, modelOrder: modelOrder)
    }
}
