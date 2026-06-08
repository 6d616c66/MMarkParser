// Ported from elk-source/plugins/org.eclipse.elk.alg.layered/src/org/eclipse/elk/alg/layered/p5edges/orthogonal/HyperEdgeSegmentDependency.java

import Foundation

internal final class org_eclipse_elk_alg_layered_p5edges_orthogonal_HyperEdgeSegmentDependency: CustomStringConvertible {
    internal enum DependencyType: String {
        case REGULAR
        case CRITICAL
    }

    internal static let CRITICAL_DEPENDENCY_WEIGHT = 1

    internal let type: DependencyType
    internal var source: org_eclipse_elk_alg_layered_p5edges_orthogonal_HyperEdgeSegment?
    internal var target: org_eclipse_elk_alg_layered_p5edges_orthogonal_HyperEdgeSegment?
    internal let weight: Int

    private init(
        _ type: DependencyType,
        _ source: org_eclipse_elk_alg_layered_p5edges_orthogonal_HyperEdgeSegment,
        _ target: org_eclipse_elk_alg_layered_p5edges_orthogonal_HyperEdgeSegment,
        _ weight: Int
    ) {
        self.type = type
        self.weight = weight
        setSource(source)
        setTarget(target)
    }

    @discardableResult
    internal static func createAndAddRegular(
        _ source: org_eclipse_elk_alg_layered_p5edges_orthogonal_HyperEdgeSegment,
        _ target: org_eclipse_elk_alg_layered_p5edges_orthogonal_HyperEdgeSegment,
        _ weight: Int
    ) -> org_eclipse_elk_alg_layered_p5edges_orthogonal_HyperEdgeSegmentDependency {
        org_eclipse_elk_alg_layered_p5edges_orthogonal_HyperEdgeSegmentDependency(.REGULAR, source, target, weight)
    }

    @discardableResult
    internal static func createAndAddCritical(
        _ source: org_eclipse_elk_alg_layered_p5edges_orthogonal_HyperEdgeSegment,
        _ target: org_eclipse_elk_alg_layered_p5edges_orthogonal_HyperEdgeSegment
    ) -> org_eclipse_elk_alg_layered_p5edges_orthogonal_HyperEdgeSegmentDependency {
        org_eclipse_elk_alg_layered_p5edges_orthogonal_HyperEdgeSegmentDependency(
            .CRITICAL,
            source,
            target,
            CRITICAL_DEPENDENCY_WEIGHT
        )
    }

    internal func remove() {
        setSource(nil)
        setTarget(nil)
    }

    internal func reverse() {
        let oldSource = source
        let oldTarget = target
        setSource(oldTarget)
        setTarget(oldSource)
    }

    internal func getType() -> DependencyType {
        type
    }

    internal func getSource() -> org_eclipse_elk_alg_layered_p5edges_orthogonal_HyperEdgeSegment? {
        source
    }

    internal func setSource(_ newSource: org_eclipse_elk_alg_layered_p5edges_orthogonal_HyperEdgeSegment?) {
        if let source {
            source.removeOutgoingSegmentDependency(self)
        }

        source = newSource

        if let source {
            source.appendOutgoingSegmentDependency(self)
        }
    }

    internal func getTarget() -> org_eclipse_elk_alg_layered_p5edges_orthogonal_HyperEdgeSegment? {
        target
    }

    internal func setTarget(_ newTarget: org_eclipse_elk_alg_layered_p5edges_orthogonal_HyperEdgeSegment?) {
        if let target {
            target.removeIncomingSegmentDependency(self)
        }

        target = newTarget

        if let target {
            target.appendIncomingSegmentDependency(self)
        }
    }

    internal func getWeight() -> Int {
        weight
    }

    internal func toString() -> String {
        "\(String(describing: source))->\(String(describing: target)) (\(type.rawValue))"
    }

    internal var description: String {
        toString()
    }
}
