// Generated from ELK Java source
// Source of truth: elk-source (Java)
// DO NOT EDIT MANUALLY. Regenerate instead.

// Java source: plugins/org.eclipse.elk.alg.layered/src/org/eclipse/elk/alg/layered/intermediate/wrapping/ARDCutIndexHeuristic.java

import Foundation

internal class org_eclipse_elk_alg_layered_intermediate_wrapping_ARDCutIndexHeuristic: org_eclipse_elk_alg_layered_intermediate_wrapping_ICutIndexCalculator {
    internal init() {}

    internal func getCutIndexes(
        _ graph: LGraph,
        _ gs: org_eclipse_elk_alg_layered_intermediate_wrapping_GraphStats
    ) -> [Int] {
        let rows = Self.getChunkCount(gs)

        // The number of cuts is one less than the number of rows.
        var cuts: [Int] = []
        let step = Double(gs.longestPath) / Double(rows)
        if rows > 1 {
            for idx in 1..<rows {
                cuts.append(Int(round(Double(idx) * step)))
            }
        }

        return cuts
    }

    internal class func getChunkCount(_ gs: org_eclipse_elk_alg_layered_intermediate_wrapping_GraphStats) -> Int {
        let rowsd = sqrt(gs.getSumWidth() / (gs.dar * gs.getMaxHeight()))
        var rows = Int(round(rowsd))
        rows = min(rows, gs.longestPath)
        return rows
    }

    internal func guaranteeValid() -> Bool {
        false
    }
}
