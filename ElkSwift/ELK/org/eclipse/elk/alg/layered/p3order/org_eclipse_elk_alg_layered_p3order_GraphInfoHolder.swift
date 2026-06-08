// Ported from elk-source/plugins/org.eclipse.elk.alg.layered/src/org/eclipse/elk/alg/layered/p3order/GraphInfoHolder.java
import Foundation

internal enum org_eclipse_elk_alg_layered_p3order_LayerSweepCrossingMinimizer_CrossMinType {
    case BARYCENTER
    case MEDIAN
    case GREEDY_SWITCH
    case INTERACTIVE
    case NONE
}

internal class org_eclipse_elk_alg_layered_p3order_GraphInfoHolder:
    org_eclipse_elk_alg_layered_p3order_counting_IInitializable,
    CustomStringConvertible
{
    internal var _lGraph: org_eclipse_elk_alg_layered_graph_LGraph

    internal var _currentNodeOrder: [[org_eclipse_elk_alg_layered_graph_LNode]]
    internal var _currentlyBestNodeAndPortOrder: org_eclipse_elk_alg_layered_p3order_SweepCopy?
    internal var _bestNodeAndPortOrder: org_eclipse_elk_alg_layered_p3order_SweepCopy?
    internal var _portPositions = SharedIntArray()

    internal var _useBottomUp = false

    internal var _childGraphs: [org_eclipse_elk_alg_layered_graph_LGraph] = []
    internal var _hasExternalPorts = false
    internal var _hasParent = false
    internal weak var _parentGraphData: org_eclipse_elk_alg_layered_p3order_GraphInfoHolder?
    internal weak var _parent: org_eclipse_elk_alg_layered_graph_LNode?
    internal lazy var _layerSweepTypeDecider = org_eclipse_elk_alg_layered_p3order_LayerSweepTypeDecider(self)

    internal var _crossMinimizer: org_eclipse_elk_alg_layered_p3order_ICrossingMinimizationHeuristic
    internal var _portDistributor: any org_eclipse_elk_alg_layered_p3order_ISweepPortDistributor
    internal var _crossingsCounter: org_eclipse_elk_alg_layered_p3order_counting_AllCrossingsCounter
    internal var _nPorts = 0
    internal var _originalCrossMinType: org_eclipse_elk_alg_layered_p3order_CrossMinType = .BARYCENTER

    internal init(
        _ graph: org_eclipse_elk_alg_layered_graph_LGraph,
        _ crossMinType: org_eclipse_elk_alg_layered_p3order_LayerSweepCrossingMinimizer_CrossMinType,
        _ graphs: [org_eclipse_elk_alg_layered_p3order_GraphInfoHolder],
        _ originalCrossMinType: org_eclipse_elk_alg_layered_p3order_CrossMinType = .BARYCENTER
    ) {
        _originalCrossMinType = originalCrossMinType
        _lGraph = graph
        _currentNodeOrder = graph.toNodeArray()

        _parent = _lGraph.getParentNode()
        _hasParent = _parent != nil
        if let parentGraph = _parent?.getGraph() {
            let parentId = parentGraph.id
            if parentId >= 0, parentId < graphs.count {
                _parentGraphData = graphs[parentId]
            }
        }

        let graphProperties = graph.getProperty(org_eclipse_elk_alg_layered_options_InternalProperties.GRAPH_PROPERTIES) as? Set<org_eclipse_elk_alg_layered_options_GraphProperties> ?? []
        _hasExternalPorts = graphProperties.contains(.EXTERNAL_PORTS)
        _childGraphs = []

        _crossingsCounter = org_eclipse_elk_alg_layered_p3order_counting_AllCrossingsCounter(_currentNodeOrder)

        let random = graph.getProperty(org_eclipse_elk_alg_layered_options_InternalProperties.RANDOM) as? Random
        let randomValue: Any? = random
        let forceModelOrder = graph.getProperty("org.eclipse.elk.layered.crossingMinimization.forceNodeModelOrder") as? Bool ?? false

        // Java: portDistributor = ISweepPortDistributor.create(crossMinType, random, currentNodeOrder)
        // For GREEDY_SWITCH, Java uses GreedyPortDistributor (greedy port swapping via CrossingsCounter).
        // For BARYCENTER/MEDIAN, random.nextBoolean() chooses between NodeRelative and LayerTotal.
        let sharedPortDistributor: org_eclipse_elk_alg_layered_p3order_AbstractBarycenterPortDistributor?
        if crossMinType == .GREEDY_SWITCH {
            sharedPortDistributor = nil
            _portDistributor = org_eclipse_elk_alg_layered_p3order_GreedyPortDistributor()
        } else if random?.nextBoolean() ?? true {
            let pd = org_eclipse_elk_alg_layered_p3order_NodeRelativePortDistributor(_currentNodeOrder.count)
            sharedPortDistributor = pd
            _portDistributor = pd
        } else {
            let pd = org_eclipse_elk_alg_layered_p3order_LayerTotalPortDistributor(_currentNodeOrder.count)
            sharedPortDistributor = pd
            _portDistributor = pd
        }

        // Initialize _crossMinimizer with a placeholder first so all stored properties
        // are set before we can pass `self` to GreedySwitchHeuristic.
        _crossMinimizer = org_eclipse_elk_alg_layered_p3order_MedianHeuristic(randomValue)

        switch crossMinType {
        case .BARYCENTER:
            let constraintResolver = org_eclipse_elk_alg_layered_p3order_ForsterConstraintResolver(_currentNodeOrder)
            if let dist = sharedPortDistributor {
                if forceModelOrder {
                    _crossMinimizer = org_eclipse_elk_alg_layered_p3order_ModelOrderBarycenterHeuristic(
                        constraintResolver,
                        randomValue,
                        dist,
                        _currentNodeOrder
                    )
                } else {
                    _crossMinimizer = org_eclipse_elk_alg_layered_p3order_BarycenterHeuristic(
                        constraintResolver,
                        randomValue,
                        dist,
                        _currentNodeOrder
                    )
                }
            }
        case .MEDIAN:
            break // already set above
        case .GREEDY_SWITCH:
            _crossMinimizer = org_eclipse_elk_alg_layered_intermediate_greedyswitch_GreedySwitchHeuristic(
                _originalCrossMinType, self)
        case .INTERACTIVE, .NONE:
            break // already set above
        }

        initializeByTraversal()
        _useBottomUp = _layerSweepTypeDecider.useBottomUp()
    }

    internal func dontSweepInto() -> Bool {
        _useBottomUp
    }

    internal func lGraph() -> org_eclipse_elk_alg_layered_graph_LGraph {
        _lGraph
    }

    internal func currentNodeOrder() -> [[org_eclipse_elk_alg_layered_graph_LNode]] {
        _currentNodeOrder
    }

    internal func setCurrentNodeOrder(_ order: [[org_eclipse_elk_alg_layered_graph_LNode]]) {
        _currentNodeOrder = order
    }

    internal func currentlyBestNodeAndPortOrder() -> org_eclipse_elk_alg_layered_p3order_SweepCopy? {
        _currentlyBestNodeAndPortOrder
    }

    internal func setCurrentlyBestNodeAndPortOrder(_ currentlyBestNodeAndPortOrder: org_eclipse_elk_alg_layered_p3order_SweepCopy?) {
        _currentlyBestNodeAndPortOrder = currentlyBestNodeAndPortOrder
    }

    internal func bestNodeNPortOrder() -> org_eclipse_elk_alg_layered_p3order_SweepCopy? {
        _bestNodeAndPortOrder
    }

    internal func setBestNodeNPortOrder(_ bestNodeNPortOrder: org_eclipse_elk_alg_layered_p3order_SweepCopy?) {
        _bestNodeAndPortOrder = bestNodeNPortOrder
    }

    internal func crossCounter() -> org_eclipse_elk_alg_layered_p3order_counting_AllCrossingsCounter {
        _crossingsCounter
    }

    internal func crossMinimizer() -> org_eclipse_elk_alg_layered_p3order_ICrossingMinimizationHeuristic {
        _crossMinimizer
    }

    internal func portDistributor() -> any org_eclipse_elk_alg_layered_p3order_ISweepPortDistributor {
        _portDistributor
    }

    internal func parent() -> org_eclipse_elk_alg_layered_graph_LNode {
        _parent ?? org_eclipse_elk_alg_layered_graph_LNode(org_eclipse_elk_alg_layered_graph_LGraph())
    }

    internal func hasParent() -> Bool {
        _hasParent
    }

    internal func childGraphs() -> [org_eclipse_elk_alg_layered_graph_LGraph] {
        _childGraphs
    }

    internal func hasExternalPorts() -> Bool {
        _hasExternalPorts
    }

    internal var description: String {
        String(describing: _currentNodeOrder)
    }

    internal func getBestSweep() -> org_eclipse_elk_alg_layered_p3order_SweepCopy? {
        crossMinDeterministic() ? currentlyBestNodeAndPortOrder() : bestNodeNPortOrder()
    }

    internal func parentGraphData() -> org_eclipse_elk_alg_layered_p3order_GraphInfoHolder? {
        _parentGraphData
    }

    internal func crossMinDeterministic() -> Bool {
        _crossMinimizer.isDeterministic()
    }

    internal func crossMinAlwaysImproves() -> Bool {
        _crossMinimizer.alwaysImproves()
    }

    internal func portPositions() -> SharedIntArray {
        _portPositions
    }

    internal func initAtNodeLevel(
        _ l: Int,
        _ n: Int,
        _ nodeOrder: [[org_eclipse_elk_alg_layered_graph_LNode]]
    ) {
        guard l >= 0, l < nodeOrder.count, n >= 0, n < nodeOrder[l].count else {
            return
        }

        let node = nodeOrder[l][n]
        if let nestedGraph = node.getNestedGraph() {
            _childGraphs.append(nestedGraph)
        }
    }

    internal func initAtPortLevel(
        _ l: Int,
        _ n: Int,
        _ p: Int,
        _ nodeOrder: [[org_eclipse_elk_alg_layered_graph_LNode]]
    ) {
        _ = l
        _ = n
        _ = p
        _ = nodeOrder
        _nPorts += 1
    }

    internal func initAfterTraversal() {
        _portPositions = SharedIntArray(repeating: 0, count: _nPorts)
    }

    /// Matches Java's IInitializable.init(List<IInitializable>, LNode[][]):
    /// traverses layers → nodes → ports → edges, calling init methods on ALL components.
    /// Java's initializables list: [this, crossingsCounter, layerSweepTypeDecider, portDistributor, constraintResolver, crossMinimizer]
    internal func initializeByTraversal() {
        // Collect references to all initializable components
        // Java list order: this, crossingsCounter, layerSweepTypeDecider, portDistributor, constraintResolver, crossMinimizer
        let crossingsCounter = _crossingsCounter
        let portDistributor = _portDistributor as? org_eclipse_elk_alg_layered_p3order_AbstractBarycenterPortDistributor
        let greedyPortDistributor = _portDistributor as? org_eclipse_elk_alg_layered_p3order_GreedyPortDistributor
        let barycenterHeuristic = _crossMinimizer as? org_eclipse_elk_alg_layered_p3order_BarycenterHeuristic
        let constraintResolver = barycenterHeuristic?.constraintResolver
        let greedySwitchHeuristic = _crossMinimizer as? org_eclipse_elk_alg_layered_intermediate_greedyswitch_GreedySwitchHeuristic

        for (layerIndex, layer) in _currentNodeOrder.enumerated() {
            _layerSweepTypeDecider.initAtLayerLevel(layerIndex, _currentNodeOrder)
            constraintResolver?.initAtLayerLevel(layerIndex, _currentNodeOrder)
            barycenterHeuristic?.initAtLayerLevel(layerIndex, _currentNodeOrder)
            greedySwitchHeuristic?.initAtLayerLevel(layerIndex, _currentNodeOrder)

            for (nodeIndex, node) in layer.enumerated() {
                initAtNodeLevel(layerIndex, nodeIndex, _currentNodeOrder)
                crossingsCounter.initAtNodeLevel(layerIndex, nodeIndex, _currentNodeOrder)
                _layerSweepTypeDecider.initAtNodeLevel(layerIndex, nodeIndex, _currentNodeOrder)
                portDistributor?.initAtNodeLevel(layerIndex, nodeIndex, _currentNodeOrder)
                greedyPortDistributor?.initAtNodeLevel(layerIndex, nodeIndex, _currentNodeOrder)
                constraintResolver?.initAtNodeLevel(layerIndex, nodeIndex, _currentNodeOrder)

                let ports = node.getPorts()
                for portIndex in ports.indices {
                    initAtPortLevel(layerIndex, nodeIndex, portIndex, _currentNodeOrder)
                    crossingsCounter.initAtPortLevel(layerIndex, nodeIndex, portIndex, _currentNodeOrder)
                    portDistributor?.initAtPortLevel(layerIndex, nodeIndex, portIndex, _currentNodeOrder)
                    greedySwitchHeuristic?.initAtPortLevel(layerIndex, nodeIndex, portIndex, _currentNodeOrder)

                    let connectedEdges = ports[portIndex].getConnectedEdges()
                    for (edgeIndex, edge) in connectedEdges.enumerated() {
                        crossingsCounter.initAtEdgeLevel(layerIndex, nodeIndex, portIndex, edgeIndex, edge, _currentNodeOrder)
                    }
                }
            }
        }

        initAfterTraversal()
        crossingsCounter.initAfterTraversal()
        portDistributor?.initAfterTraversal()
        greedyPortDistributor?.initAfterTraversal()
        barycenterHeuristic?.initAfterTraversal()
        greedySwitchHeuristic?.initAfterTraversal()
    }

    internal func graphPropertiesKey() -> String {
        "graphProperties"
    }

    internal func randomKey() -> String {
        "random"
    }

    internal func crossingMinForceNodeModelOrderKey() -> String {
        "org.eclipse.elk.layered.crossingMinimization.forceNodeModelOrder"
    }
}
