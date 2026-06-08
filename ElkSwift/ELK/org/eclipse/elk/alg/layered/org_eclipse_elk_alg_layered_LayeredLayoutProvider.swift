import Foundation

/**
 * Layout provider to connect the layered layouter to the Eclipse based layout services.
 *
 * @see ElkLayered
 */
internal final class LayeredLayoutProvider: AbstractLayoutProvider {

    // MARK: - Variables

    /** the layout algorithm used for regular layout runs. */
    internal let elkLayered = ElkLayered()


    // MARK: - Regular Layout

    internal override func layout(layoutGraph elkgraph: ElkNode, progressMonitor: IElkProgressMonitor) throws {
        // Import the graph
        let graphTransformer = ElkGraphTransformer()
        guard let layeredGraph = try graphTransformer.importGraph(elkgraph) else { return }

        // Check if hierarchy handling for a compound graph is requested
        let hierHandling = elkgraph.getProperty(LayeredOptions.HIERARCHY_HANDLING) as? HierarchyHandling
        if hierHandling == HierarchyHandling.INCLUDE_CHILDREN {
            elkLayered.doCompoundLayout(layeredGraph, progressMonitor)
        } else {
            elkLayered.doLayout(layeredGraph, progressMonitor)
        }

        if !progressMonitor.isCanceled() {
            graphTransformer.applyLayout(layeredGraph)
        }
    }


    // MARK: - Layout Testing

    internal func startLayoutTest(_ elkgraph: ElkNode) throws -> ElkLayered.TestExecutionState {
        let graphImporter = ElkGraphTransformer()
        let layeredGraph = try graphImporter.importGraph(elkgraph)
        guard let layeredGraph = layeredGraph else {
            return elkLayered.prepareLayoutTest(LGraph())
        }

        return elkLayered.prepareLayoutTest(layeredGraph)
    }

    internal func getLayoutAlgorithm() -> ElkLayered {
        return elkLayered
    }

    internal func setTestController(_ controller: TestController?) {
        elkLayered.setTestController(controller)
    }
}
