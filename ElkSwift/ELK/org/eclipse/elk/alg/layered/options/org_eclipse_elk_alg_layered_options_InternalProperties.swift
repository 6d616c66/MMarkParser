// Generated from ELK Java source
// Source of truth: elk-source (Java)
// DO NOT EDIT MANUALLY. Regenerate instead.

// Java source: plugins/org.eclipse.elk.alg.layered/src/org/eclipse/elk/alg/layered/options/InternalProperties.java

import Foundation

internal final class org_eclipse_elk_alg_layered_options_InternalProperties {

    // Origin and bendpoints
    internal static let ORIGIN = Property<Any>("origin")
    internal static let ORIGINAL_BENDPOINTS = Property<Any>("originalBendpoints")
    internal static let ORIGINAL_DUMMY_NODE_POSITION = Property<Any>("originalDummyNodePosition")
    internal static let ORIGINAL_PORT_CONSTRAINTS = Property<Any>("originalPortConstraints")

    // Long edge properties
    internal static let LONG_EDGE_SOURCE = Property<Any>("longEdgeSource")
    internal static let LONG_EDGE_TARGET = Property<Any>("longEdgeTarget")
    internal static let LONG_EDGE_TARGET_NODE = Property<Any>("longEdgeTargetNode")
    internal static let LONG_EDGE_HAS_LABEL_DUMMIES = Property<Any>("longEdgeHasLabelDummies")

    // In-layer properties
    internal static let IN_LAYER_LAYOUT_UNIT = Property<Any>("inLayerLayoutUnit")
    internal static let IN_LAYER_SUCCESSOR_CONSTRAINTS = Property<Any>("inLayerSuccessorConstraint")
    internal static let IN_LAYER_CONSTRAINT = Property<Any>("inLayerConstraint")

    // Graph properties
    internal static let GRAPH_PROPERTIES = Property<Any>("graphProperties")
    internal static let BARYCENTER_ASSOCIATES = Property<Any>("barycenterAssociates")

    // Model order
    internal static let MODEL_ORDER = Property<Int>("modelOrder")
    internal static let MAX_MODEL_ORDER_NODES = Property<Int>("modelOrder.maximum")
    internal static let CB_NUM_MODEL_ORDER_GROUPS = Property<Int>("modelOrderGroups.cb.number")
    internal static let TARGET_NODE_MODEL_ORDER = Property<Int>("targetNode.modelOrder")

    // Cycle properties
    internal static let CYCLIC = Property<Bool>("cyclic")
    internal static let REVERSED = Property<Bool>("reversed")
    internal static let IS_PART_OF_CYCLE = Property<Bool>("isPartOfCycle")

    // Collect properties
    internal static let INPUT_COLLECT = Property<Bool>("inputCollect")
    internal static let OUTPUT_COLLECT = Property<Bool>("outputCollect")

    // Spacing and layout
    internal static let SPACINGS = Property<Any>("spacings")
    internal static let PORT_DUMMY = Property<Any>("portDummy")

    // Processor configuration
    internal static let PROCESSORS = Property<[AnyGraphProcessor]>("processors")

    // Tarjan's algorithm properties
    internal static let TARJAN_LOWLINK = Property<Int>("tarjan.lowlink")
    internal static let TARJAN_ID = Property<Int>("tarjan.id")
    internal static let TARJAN_ON_STACK = Property<Bool>("tarjan.onStack")

    // External port properties
    internal static let EXT_PORT_SIDE = Property<PortSide>("extPort.side")
    internal static let EXT_PORT_CONNECTIONS = Property<Set<PortSide>>("extPort.connections")
    internal static let EXT_PORT_SIZE = Property<Any>("extPort.size")

    // End label properties
    internal static let END_LABEL_EDGE = Property<Any>("endLabel.edge")
    internal static let END_LABELS = Property<Any>("endLabels")

    // Edge constraint
    internal static let EDGE_CONSTRAINT = Property<Any>("edgeConstraint")

    // Fuzziness for overlap checks
    internal static let FUZZINESS: Double = 0.0001

    // Comment properties
    internal static let TOP_COMMENTS = Property<Any>("topComments")
    internal static let BOTTOM_COMMENTS = Property<Any>("bottomComments")
    internal static let COMMENT_CONN_PORT = Property<Any>("commentConnPort")

    // Spline routing properties
    internal static let SPLINE_ROUTE_START = Property<Any>("spline.route.start")
    internal static let SPLINE_EDGE_CHAIN = Property<Any>("spline.edgeChain")
    internal static let SPLINE_NS_PORT_Y_COORD = Property<Double>("spline.nsPortY")
    internal static let SPLINE_SURVIVING_EDGE = Property<Any>("spline.survivingEdge")

    // Dummy node type
    internal static let DUMMY = Property<Bool>("dummy")

    // Compound / hierarchy properties
    internal static let COMPOUND_NODE = Property<Bool>("compoundNode")
    internal static let CROSS_HIERARCHY_MAP = Property<Any>("crossHierarchyMap")
    internal static let INSIDE_CONNECTIONS = Property<Bool>("insideConnections")

    // Coordinate system
    internal static let COORDINATE_SYSTEM_ORIGIN = Property<Any>("coordinateSystemOrigin")

    // Bounding box (used in force layout)
    internal static let BB_UPLEFT = Property<Any>("bb.upLeft")
    internal static let BB_LOWRIGHT = Property<Any>("bb.lowRight")

    // Random number generator
    internal static let RANDOM = Property<Any>("random")

    // Label side
    internal static let LABEL_SIDE = Property<Any>("labelSide")

    // Max edge thickness
    internal static let MAX_EDGE_THICKNESS = Property<Double>("maxEdgeThickness")

    // Port ratio or position
    internal static let PORT_RATIO_OR_POSITION = Property<Double>("portRatioOrPosition")

    // Target offset
    internal static let TARGET_OFFSET = Property<Any>("targetOffset")

    // Unnecessary bendpoints (compound graph processing)
    internal static let UNNECESSARY_BENDPOINTS = Property<Bool>("unnecessaryBendpoints")

    // Original label edge (compound graph processing)
    internal static let ORIGINAL_LABEL_EDGE = Property<Any>("originalLabelEdge")

    // Represented labels (center label dummies)
    internal static let REPRESENTED_LABELS = Property<Any>("representedLabels")

    // Hidden nodes (layer constraint preprocessing)
    internal static let HIDDEN_NODES = Property<Any>("hiddenNodes")

    // Original opposite port (layer constraint preprocessing)
    internal static let ORIGINAL_OPPOSITE_PORT = Property<Any>("originalOppositePort")

    // Long edge before label dummy
    internal static let LONG_EDGE_BEFORE_LABEL_DUMMY = Property<Bool>("longEdgeBeforeLabelDummy")

    // External port replaced dummies (hierarchical port constraint processing)
    internal static let EXT_PORT_REPLACED_DUMMIES = Property<[LNode]>("extPort.replacedDummies")
    internal static let EXT_PORT_REPLACED_DUMMY = Property<LNode>("extPort.replacedDummy")

    // Crossing hint (used by NorthSouthPortPreprocessor)
    internal static let CROSSING_HINT = Property<Int>("crossingHint")

    // Self loop properties
    internal static let SELF_LOOP_HOLDER = Property<Any>("selfLoopHolder")

    internal init() {}
}
